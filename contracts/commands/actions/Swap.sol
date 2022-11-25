/*
Command         Action.Swap
Description     Swap token in pair
Parents         1
Childs          1 [onAcceptTokensTransfer]
Target          https://github.com/broxus/flatqube-contracts/blob/master/contracts/DexPair.sol#L232

*/

pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./Transfer.sol";

import "tip3/contracts/interfaces/IAcceptTokensTransferCallback.sol";
import "flatqube/contracts/libraries/DexOperationTypes.sol";


struct SwapActionData {
    address token;
    uint128 amount;
    address pair;
    address remainingGasTo;
    uint128 value;
    uint8 flag;
}


abstract contract SwapAction is TransferAction, IAcceptTokensTransferCallback {

    function encodeSwapActionData(
        AmountExtended amount, address pair, uint128 value, uint8 flag
    ) public pure returns (TvmCell encoded) {
        return abi.encode(amount, pair, value, flag);
    }

    function decodeSwapActionData(TvmCell params, ExecutionData data) public pure returns (SwapActionData decoded) {
        (AmountExtended amount, address pair, uint128 value, uint8 flag) =
            abi.decode(params, (AmountExtended, address, uint128, uint8));
        uint128 amountDecoded = ExtendedTypes.decodeAmountExtended(amount, data);
        return SwapActionData(data.token, amountDecoded, pair, data.callData.sender, value, flag);
    }

    function _checkSwapResponse(address sender) internal pure {
        address dex_vault = address.makeAddrStd(0, Constants.DEX_VAULT_VALUE);
        require(sender == dex_vault, ErrorCodes.WRONG_ACTION_CALLBACK);
    }

    function _swap(SwapActionData data, TvmCell meta) internal {
        TvmCell payload = _buildSwapPayload(meta);
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

    function _buildSwapPayload(TvmCell meta) private pure returns (TvmCell) {
        TvmBuilder builder;
        builder.store(DexOperationTypes.EXCHANGE);  // operation type
        builder.store(uint64(0));                   // id
        builder.store(uint128(0));                  // deploy wallet grams
        builder.store(uint128(0));                  // expected amount (minimum)
        builder.storeRef(meta);                     // [ref] on success payload
        return builder.toCell();
    }

}
