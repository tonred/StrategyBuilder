/*
Command         Action.Deposit
Description     Deposit liquidity to pool
Parents         1
Childs          1  [onAcceptTokensMint]
Target          https://github.com/broxus/flatqube-contracts/blob/master/contracts/DexPair.sol#L232

*/

pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./Transfer.sol";

import "tip3/contracts/interfaces/IAcceptTokensMintCallback.sol";
import "flatqube/contracts/libraries/DexOperationTypes.sol";


struct DepositActionData {
    address token;
    uint128 amount;
    address pair;
    address remainingGasTo;
    uint128 value;
    uint8 flag;
}


abstract contract DepositAction is TransferAction, IAcceptTokensMintCallback {

    function encodeDepositActionData(
        AmountExtended amount, address pair, uint128 value, uint8 flag
    ) public pure returns (TvmCell encoded) {
        return abi.encode(amount, pair, value, flag);
    }

    function decodeDepositActionData(TvmCell params, ExecutionData data) public pure returns (DepositActionData decoded) {
        (AmountExtended amount, address pair, uint128 value, uint8 flag)
            = abi.decode(params, (AmountExtended, address, uint128, uint8));
        uint128 amountDecoded = ExtendedTypes.decodeAmountExtended(amount, data);
        return DepositActionData(data.token, amountDecoded, pair, data.callData.sender, value, flag);
    }

    function _checkDepositResponse(TvmCell params) internal pure {
        (/*amount*/, address pair, /*value*/, /*flag*/) = abi.decode(params, (AmountExtended, address, uint128, uint8));
        require(msg.sender == pair, ErrorCodes.WRONG_ACTION_CALLBACK);
    }

    function _deposit(DepositActionData data, TvmCell meta) internal {
        TvmCell payload = _buildDepositPayload(meta);
        _transfer(TransferActionData({
            token: data.token,
            amount: data.amount,
            recipient: data.pair,
            isDeployWallet: false,
            remainingGasTo: data.remainingGasTo,
            payload: payload,
            value: data.value,
            flag: data.flag,
            force: false
        }));
    }

    function _buildDepositPayload(TvmCell meta) private pure returns (TvmCell) {
        TvmBuilder builder;
        builder.store(DexOperationTypes.DEPOSIT_LIQUIDITY); // operation type
        builder.store(uint64(0));                           // id
        builder.store(uint128(0));                          // deploy wallet grams
        builder.storeRef(meta);                             // [ref] on success payload
        return builder.toCell();
    }

}
