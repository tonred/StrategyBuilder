pragma ever-solidity ^0.63.0;


interface IUpgradable {
    event CodeUpgraded();
    function upgrade(TvmCell code) external internalMsg;
    // function onCodeUpgrade(TvmCell input) private {...}
}
