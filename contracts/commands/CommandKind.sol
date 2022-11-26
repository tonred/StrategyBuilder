pragma ever-solidity ^0.63.0;


enum CommandKind {
    NOTHING,    // 0 (used also for TokenInput)
    TRANSFER,   // 1
    SWAP,       // 2
    DEPOSIT,    // 3
    FARM        // 4
}
