pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../InputKind.sol";
import "../../utils/ExtendedTypes.sol";


struct TokenInputData {
    address token;
    uint128 minAmount;
    uint128 minGas;
}


abstract contract TokenInput {

    function hashTokenInput(InputKind kind, address token, AddressExtended sender) public pure returns (uint256 hash) {
        TvmCell cell = abi.encode(kind, token, sender);
        return tvm.hash(cell);
    }

    function encodeTokenInputData(address token, uint128 minAmount, uint128 minGas) public pure returns (TvmCell encoded) {
        return abi.encode(token, minAmount, minGas);
    }

    function decodeTokenInputData(TvmCell params) public pure returns (TokenInputData data) {
        (address token, uint128 minAmount, uint128 minGas) = abi.decode(params, (address, uint128, uint128));
        return TokenInputData(token, minAmount, minGas);
    }

    function tokenInputToken(TvmCell params) public pure returns (address token) {
        return params.toSlice().decode(address);
    }

    function _checkTokenInput(TokenInputData data, address token, uint128 amount, uint128 gas) internal pure returns (bool) {
        return token == data.token && amount >= data.minAmount && gas >= data.minGas;
    }

}
