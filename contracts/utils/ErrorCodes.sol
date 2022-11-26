pragma ever-solidity ^0.63.0;


library ErrorCodes {

    // Common
    uint16 constant IS_NOT_OWNER            = 1001;
    uint16 constant IS_NOT_WALLET           = 1002;

    // Platform
    uint16 constant IS_NOT_ROOT             = 2001;

    // Wallet Manager
    uint16 constant IS_NOT_TOKEN            = 3001;
    uint16 constant NO_TOKEN_WALLET         = 3002;

    uint16 constant INVALID_EXTENDED_TYPE   = 4001;

    // Actions
    uint16 constant WRONG_AMOUNT            = 5001;
    uint16 constant WRONG_ACTION_CALLBACK   = 5002;

    // Strategy
    uint16 constant INVALID_COMMAND         = 6001;

    // Strategy Builder
    uint16 constant INVALID_INPUT           = 7001;

}
