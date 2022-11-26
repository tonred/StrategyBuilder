/*
Command         Action.Unwrap
Description     Unwrap wEVER to EVER
Parents         1
Childs          1 [onAcceptTokensBurn]
Target          https://github.com/broxus/ton-wton/blob/master/everscale/contracts/Vault.sol#L230

*/

pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../Transfer.sol";


struct UnwrapActionData {
    uint128 amount;
    address remainingGasTo;
    uint128 value;
    uint8 flag;
}


abstract contract UnwrapAction is TransferAction {

    // todo sender checks
    function _unwrap(UnwrapActionData data, TvmCell meta) internal {
        address root = address.makeAddrStd(0, Constants.WEVER_ROOT_VALUE);
        address vault = address.makeAddrStd(0, Constants.WEVER_VAULT_VALUE);
        _transfer(TransferActionData({
            token: root,
            amount: data.amount,
            recipient: vault,
            isDeployWallet: false,
            remainingGasTo: data.remainingGasTo,
            payload: meta,
            value: data.value,
            flag: data.flag,
            force: false
        }));
    }

}
