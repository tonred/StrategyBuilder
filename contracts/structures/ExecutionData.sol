pragma ever-solidity ^0.63.0;

import "./CallData.sol";


struct ExecutionData {
    CallData callData;
    uint128 total;
    uint128 spent;
}
