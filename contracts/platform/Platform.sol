pragma ever-solidity ^0.63.0;

import "../utils/ErrorCodes.sol";


contract Platform {

    address static _root;
    uint8 static _platformType;
    TvmCell static _initialData;


    constructor(TvmCell code, TvmCell params) public functionID(0x4A2E4FD6) {
        require(msg.sender == _root, ErrorCodes.IS_NOT_ROOT);
        TvmCell input = abi.encode(_root, _initialData, params);
        tvm.setcode(code);
        tvm.setCurrentCode(code);
        onCodeUpgrade(input);
    }

    function onCodeUpgrade(TvmCell input) private {}

}
