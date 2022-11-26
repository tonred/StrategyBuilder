pragma ever-solidity ^0.63.0;


// from https://github.com/broxus/ton-wton/blob/master/everscale/contracts/Vault.sol#L200
interface IVault {
    function wrap(
        uint128 tokens,
        address owner_address,
        address gas_back_address,
        TvmCell payload
    ) external;
}
