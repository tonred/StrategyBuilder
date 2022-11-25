pragma ever-solidity ^0.63.0;

import "./CallData.sol";


struct ExecutionData {
    CallData callData;
    address token;
    uint128 amount;
    uint128 spent;
}
