pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../InputKind.sol";
import "../../utils/ExtendedTypes.sol";


struct TokenInputData {
    uint128 minAmount;
    uint128 minGas;
}


abstract contract TokenInput {

    function hashTokenInput(InputKind kind, address token, AddressExtended sender) public pure returns (uint256 hash) {
        TvmCell cell = abi.encode(kind, token, sender);
        return tvm.hash(cell);
    }

    function encodeTokenInputData(uint128 minAmount, uint128 minGas) public pure returns (TvmCell encoded) {
        return abi.encode(minAmount, minGas);
    }

    function decodeTokenInputData(TvmCell params) public pure returns (TokenInputData data) {
        (uint128 minAmount, uint128 minGas) = abi.decode(params, (uint128, uint128));
        return TokenInputData(minAmount, minGas);
    }

    function _checkTokenInput(TokenInputData data, uint128 amount, uint128 gas) internal pure {
        require(amount >= data.minAmount && gas >= data.minGas, ErrorCodes.INVALID_INPUT);
    }

}
