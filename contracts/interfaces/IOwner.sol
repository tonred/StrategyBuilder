pragma ever-solidity ^0.63.0;


interface IOwner {
    function onStrategyCreated(address strategy, uint64 nonce) external;
}
