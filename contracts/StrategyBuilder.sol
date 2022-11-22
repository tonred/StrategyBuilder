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


    constructor(address owner, TvmCell platformCode, TvmCell strategyCode) public {
        _owner = owner;
        _platformCode = platformCode;
        _strategyCode = strategyCode;
    }

    // todo tokens must be checked, but how... (no checks = broken strategy with same address)
    function createStrategy(StrategyData data, address[] tokens) public view responsible returns (address strategy) {
        _reserve();
        TvmCell initialParams = abi.encode(tokens);
        TvmCell initialData = _buildStrategyInitialData(data);
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

    function _buildStrategyInitialData(StrategyData data) private pure returns (TvmCell) {
        return abi.encode(data.owner, data.commands, data.inputs);
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

    function _targetBalance() internal view inline override returns (uint128) {
        return Gas.STRATEGY_BUILDER_TARGET_BALANCE;
    }

}
