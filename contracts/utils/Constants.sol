pragma ever-solidity ^0.63.0;


library Constants {

    // Denominator of all percents
    uint128 constant PERCENT_DENOMINATOR = 100_000;

    // Address of Dex Vault (for swap checking)
    uint256 constant DEX_VAULT_VALUE = 0x6fa537fa97adf43db0206b5bec98eb43474a9836c016a190ac8b792feb852230;

    // Unused (for wrap/unwrap)
    uint256 constant WEVER_ROOT_VALUE = 0xa49cd4e158a9a15555e624759e2e4e766d22600b7800d891e46f9291f044a93d;
    uint256 constant WEVER_VAULT_VALUE = 0x557957cba74ab1dc544b4081be81f1208ad73997d74ab3b72d95864a41b779a4;

}
