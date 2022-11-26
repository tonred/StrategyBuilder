pragma ever-solidity ^0.63.0;


library Gas {

    // Wallet Manager
    uint128 constant DEPLOY_WALLET_VALUE        = 0.1 ever;
    uint128 constant DEPLOY_WALLET_GRAMS        = 0.1 ever;

    // Strategy
    uint128 constant STRATEGY_TARGET_BALANCE    = 0.5 ever;
    uint128 constant MIN_CLAIM_VALUE            = 8 ever;  // more than 7 evers, see https://github.com/broxus/flatqube-dao-contracts/blob/6aa1de7ccddba14be7845ee9d574206aa5046d4b/contracts/gauge/base/gauge/GaugeHelpers.sol#L301

    // Strategy Builder
    uint128 constant BUILDER_TARGET_BALANCE     = 1 ever;
    uint128 constant DEPLOY_WALLET_TOTAL        = 0.3 ever;
    uint128 constant STRATEGY_VALUE             = 0.7 ever;

}
