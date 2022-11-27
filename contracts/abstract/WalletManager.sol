pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../utils/ErrorCodes.sol";
import "../utils/Gas.sol";

import "@broxus/contracts/contracts/libraries/MsgFlag.sol";
import "tip3/contracts/interfaces/ITokenRoot.sol";


abstract contract WalletManager {

    mapping(address /*token*/ => bool) public _pendingWallets;
    mapping(address /*token*/ => address /*wallet*/) public _wallets;
    mapping(address /*token*/ => uint128 /*value*/) public _balances;


    function _createWallets(address[] tokens) internal {
        for (address token : tokens) {
            _createWallet(token);
        }
    }

    function _createWallet(address token) internal {
        if (_wallets.exists(token) || _pendingWallets.exists(token)) {
            return;
        }
        _pendingWallets[token] = true;
        ITokenRoot(token).deployWallet{
            value: Gas.DEPLOY_WALLET_VALUE + Gas.DEPLOY_WALLET_GRAMS,
            flag: MsgFlag.SENDER_PAYS_FEES,
            bounce: false,
            callback: WalletManager.onWalletDeployed
        }({
            owner: address(this),
            deployWalletValue: Gas.DEPLOY_WALLET_GRAMS
        });
    }

    function onWalletDeployed(address wallet) public {
        address token = msg.sender;
        require(_pendingWallets.exists(token), ErrorCodes.IS_NOT_TOKEN);
        delete _pendingWallets[token];
        _wallets[token] = wallet;
        _balances[token] = 0;
    }

    function getWallet(address token) public view returns (address wallet) {
        require(_wallets.exists(token), ErrorCodes.NO_TOKEN_WALLET);
        return _wallets[token];
    }

}
