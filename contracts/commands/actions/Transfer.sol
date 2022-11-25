/*
Command         Action.Transfer
Description     Transfer TIP3 token to recipient
Parents         1
Childs          0
Target          https://github.com/broxus/tip3/blob/master/contracts/interfaces/IAcceptTokensTransferCallback.sol#L20
* can be used as a part of another action

*/

pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../../abstract/WalletManager.sol";
import "../../utils/ExtendedTypes.sol";

import "tip3/contracts/interfaces/ITokenWallet.sol";


struct TransferActionData {
    address token;
    uint128 amount;
    address recipient;
    bool isDeployWallet;
    address remainingGasTo;
    TvmCell payload;
    uint128 value;
    uint8 flag;
    bool force;
}


abstract contract TransferAction is WalletManager {

    function encodeTransferActionData(
        AmountExtended amount, AddressExtended recipient, bool isDeployWallet, TvmCell payload, uint128 value, uint8 flag
    ) public pure returns (TvmCell encoded) {
        return abi.encode(amount, recipient, isDeployWallet, payload, value, flag);
    }

    function decodeTransferActionData(TvmCell params, ExecutionData data, address owner) public pure returns (TransferActionData decoded) {
        (AmountExtended amount, AddressExtended recipient, bool isDeployWallet, TvmCell payload, uint128 value, uint8 flag) =
            abi.decode(params, (AmountExtended, AddressExtended, bool, TvmCell, uint128, uint8));
        address sender = data.callData.sender;
        uint128 amountDecoded = ExtendedTypes.decodeAmountExtended(amount, data);
        address recipientDecoded = ExtendedTypes.decodeAddressExtended(recipient, sender, owner);
        return TransferActionData(data.token, amountDecoded, recipientDecoded, isDeployWallet, sender, payload, value, flag, false);
    }

    function _transfer(TransferActionData data) internal {
        if (data.amount == 0) {
            return;
        }
        if (!data.force) {
            require(_balances[data.token] >= data.amount, ErrorCodes.WRONG_AMOUNT);
            _balances[data.token] -= data.amount;
        } else {
            _balances[data.token] = 0;
        }
        address wallet = getWallet(data.token);
        ITokenWallet(wallet).transfer{
            value: data.value,
            flag: data.flag,
            bounce: false
        }({
            amount: data.amount,
            recipient: data.recipient,
            deployWalletValue: data.isDeployWallet ? Gas.DEPLOY_WALLET_GRAMS : 0,
            remainingGasTo: data.remainingGasTo,
            notify: true,
            payload: data.payload
        });
    }

}
