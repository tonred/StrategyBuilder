/*
Command         Action.Wrap
Description     Wrap EVER to wEVER
Parents         1
Childs          1 [onAcceptTokensMint]
Target          https://github.com/broxus/ton-wton/blob/master/everscale/contracts/Vault.sol#L200

*/

pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../../../interfaces/external/WrappedEver.sol";
import "../../../utils/Constants.sol";
import "../../../utils/ErrorCodes.sol";
import "../../../utils/Gas.sol";

import "@broxus/contracts/contracts/libraries/MsgFlag.sol";


struct WrapActionData {
    uint128 amount;
    address remainingGasTo;
    uint128 value;
    uint8 flag;
}


abstract contract WrapAction {

    function _wrap(WrapActionData data, TvmCell meta) internal pure {
        require(data.amount != 0 && address(this).balance > data.amount, ErrorCodes.WRONG_AMOUNT);
        address vault = address.makeAddrStd(0, Constants.WEVER_VAULT_VALUE);
        IVault(vault).wrap{
            value: data.amount + data.value,
            flag: data.flag,
            bounce: false
        }({
            tokens: data.amount,
            owner_address: address(this),  // todo sender checks
            gas_back_address: data.remainingGasTo,
            payload: meta
        });
    }

}
