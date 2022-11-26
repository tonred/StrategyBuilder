pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./commands/Command.sol";
import "./interfaces/IUpgradable.sol";
import "./platform/Platform.sol";
import "./platform/PlatformType.sol";
import "./utils/Gas.sol";
import "./utils/TransferUtils.sol";

import "@broxus/contracts/contracts/utils/RandomNonce.sol";


struct StrategyData {
    address owner;
    mapping(uint32 /*id*/ => Command) commands;
    mapping(uint256 /*hash*/ => uint32 /*id*/) inputs;
}


contract StrategyBuilder is IUpgradable, TransferUtils, RandomNonce {

    event CreatedStrategy(address strategy, address owner);


    address public _owner;
    TvmCell public _platformCode;
    TvmCell public _strategyCode;


    modifier onlyOwner() {
        require(msg.sender == _owner, ErrorCodes.IS_NOT_OWNER);
        _;
    }


    constructor(address owner, TvmCell platformCode, TvmCell strategyCode) public {
        tvm.accept();
        _owner = owner;
        _platformCode = platformCode;
        _strategyCode = strategyCode;
    }

    function expectedStrategyValue(uint32 tokensCount) public pure responsible returns (uint128 value) {
        value = Gas.STRATEGY_VALUE + tokensCount * Gas.DEPLOY_WALLET_TOTAL;
        return {value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false} value;
    }

    function createStrategy(
        StrategyData data, uint64 nonce, address[] additionalTokens, address callbackTo
    ) public view minValue(Gas.STRATEGY_VALUE) returns (address strategy) {
        _reserve();
        checkStrategy(data);
        TvmCell initialParams = abi.encode(additionalTokens, callbackTo);
        TvmCell initialData = _buildStrategyInitialData(data, nonce);
        TvmCell stateInit = _buildPlatformStateInit(PlatformType.STRATEGY, initialData);
        strategy = new Platform{
            stateInit: stateInit,
            value: 0,
            flag: MsgFlag.ALL_NOT_RESERVED,
            bounce: true
        }(_strategyCode, initialParams);
        emit CreatedStrategy(strategy, data.owner);
        return strategy;
    }

    function checkStrategy(StrategyData data) public pure {
        require(!data.commands.exists(0), ErrorCodes.INVALID_INPUT);
        for ((, uint32 id) : data.inputs) {
            require(data.commands.exists(id), ErrorCodes.INVALID_INPUT);
        }
    }

    function drain() public onlyOwner cashBack {}


    function _buildStrategyInitialData(StrategyData data, uint64 nonce) private pure returns (TvmCell) {
        return abi.encode(data.owner, data.commands, data.inputs, nonce);
    }

    function _platformAddress(PlatformType platformType, TvmCell initialData) internal view returns (address) {
        TvmCell stateInit = _buildPlatformStateInit(platformType, initialData);
        return calcAddress(stateInit);
    }

    function _buildPlatformStateInit(PlatformType platformType, TvmCell initialData) private view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Platform,
            varInit: {
                _root: address(this),
                _platformType: uint8(platformType),
                _initialData: initialData
            },
            code: _platformCode
        });
    }

    function calcAddress(TvmCell stateInit) public pure returns (address) {
        return address(tvm.hash(stateInit));
    }

    function hashCommand(Command command) public pure returns (uint32) {
        return uint32(tvm.hash(abi.encode(command)));
    }

    function _targetBalance() internal view inline override returns (uint128) {
        return Gas.BUILDER_TARGET_BALANCE;
    }

    onBounce(TvmSlice body) external pure {
        uint32 functionId = body.decode(uint32);
        if (functionId == tvm.functionId(Platform)) {
            // strategy already exist
        }
    }


    function upgrade(TvmCell code) public internalMsg override onlyOwner {
        emit CodeUpgraded();
        TvmCell data = abi.encode(_randomNonce, _owner, _platformCode, _strategyCode);
        tvm.setcode(code);
        tvm.setCurrentCode(code);
        onCodeUpgrade(data);
    }

    function onCodeUpgrade(TvmCell input) private {
        tvm.resetStorage();
        (_randomNonce, _owner, _platformCode, _strategyCode) = abi.decode(input, (uint256, address, TvmCell, TvmCell));
    }

}
