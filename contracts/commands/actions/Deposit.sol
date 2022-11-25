/*
Command         Action.Deposit
Description     Deposit liquidity to pool
Parents         1
Childs          1 [onAcceptTokensMint]
Target          https://github.com/broxus/flatqube-contracts/blob/master/contracts/DexPair.sol#L232

*/

pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./Transfer.sol";
import "../../utils/DexUtils.sol";

import "tip3/contracts/interfaces/IAcceptTokensMintCallback.sol";
import "flatqube/contracts/libraries/DexOperationTypes.sol";


struct DepositActionData {
    address token;
    address second;
    uint128 amount;
    address lp;
    address remainingGasTo;
    uint128 value;
    uint8 flag;
}


abstract contract DepositAction is TransferAction, IAcceptTokensMintCallback {

    function encodeDepositActionData(
        address second, AmountExtended amount, address lp, uint128 value, uint8 flag
    ) public pure returns (TvmCell encoded) {
        return abi.encode(second, amount, lp, value, flag);
    }

    function decodeDepositActionData(TvmCell params, ExecutionData data) public pure returns (DepositActionData decoded) {
        (address second, AmountExtended amount, address lp, uint128 value, uint8 flag)
            = abi.decode(params, (address, AmountExtended, address, uint128, uint8));
        uint128 amountDecoded = ExtendedTypes.decodeAmountExtended(amount, data);
        return DepositActionData(data.token, second, amountDecoded, lp, data.callData.sender, value, flag);
    }

    function depositChildToken(TvmCell params) public pure returns (address token) {
        return _lp(params);
    }

    function _checkDepositResponse(TvmCell params, address sender) internal pure {
        require(sender == _lp(params), ErrorCodes.WRONG_ACTION_CALLBACK);
    }

    function _lp(TvmCell params) private pure returns (address) {
        // Based on alignment of DepositActionData:
        // cell 1: second + amount + ref to cell 2
        // cell 2: lp + value + flag
        return params.toSlice().loadRefAsSlice().decode(address);
    }

    function _deposit(DepositActionData data, TvmCell meta) internal {
        TvmCell payload = _buildDepositPayload(meta);
        address pair = DexUtils.pairAddress(data.token, data.second);
        _transfer(TransferActionData({
            token: data.token,
            amount: data.amount,
            recipient: pair,
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
