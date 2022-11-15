pragma ever-solidity ^0.63.0;

import "./CommandKind.sol";


struct Command {
    CommandKind kind;
    TvmCell params;
    uint32 childID;
    uint32 nextID;
}
