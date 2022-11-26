pragma ever-solidity ^0.63.0;


// from https://github.com/broxus/flatqube-dao-contracts/blob/master/contracts/libraries/Callback.sol
library Callback {
    struct CallMeta {
        uint32 call_id;
        uint32 nonce;
        address send_gas_to;
    }
}


// from https://github.com/broxus/flatqube-dao-contracts/blob/master/contracts/gauge/base/gauge/GaugeBase.sol#L202
interface IGaugeBase {
    function claimReward(Callback.CallMeta meta) external;
}
