pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./commands/Command.sol";
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


contract StrategyBuilder is TransferUtils, RandomNonce {

    event NewStrategy(address strategy, address owner);


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

    // todo tokens must be checked, but how... (no checks = broken strategy with same address)
    function createStrategy(StrategyData data, address[] tokens, uint64 nonce) public view responsible returns (address strategy) {
        _reserve();
        checkStrategy(data);
        TvmCell initialParams = abi.encode(tokens);
        TvmCell initialData = _buildStrategyInitialData(data, nonce);
        TvmCell stateInit = _buildPlatformStateInit(PlatformType.STRATEGY, initialData);
        uint128 value = Gas.STRATEGY_VALUE + uint128(tokens.length) * Gas.DEPLOY_WALLET_TOTAL;
        strategy = new Platform{
            stateInit: stateInit,
            value: value,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: true
        }(_strategyCode, initialParams);
        emit NewStrategy(strategy, data.owner);
        return {value: 0, flag: MsgFlag.SENDER_PAYS_FEES, bounce: false} strategy;
    }

    function checkStrategy(StrategyData data) public pure {
        require(!data.commands.exists(0), ErrorCodes.INVALID_INPUT);
        for ((, uint32 id) : data.inputs) {
            require(data.commands.exists(id), ErrorCodes.INVALID_INPUT);
        }
    }

//    function drain() public onlyOwner cashBack {}
    // todo only for dev
    function drain() public view onlyOwner {
        msg.sender.transfer({value: 0, flag: MsgFlag.ALL_NOT_RESERVED, bounce: false});
    }


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
        return Gas.STRATEGY_BUILDER_TARGET_BALANCE;
    }

}
