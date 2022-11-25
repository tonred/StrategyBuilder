pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../InputKind.sol";
import "../../utils/ExtendedTypes.sol";


struct TokenInputData {
    AddressExtended sender;
    uint128 minAmount;
    uint128 minGas;
}


// todo can be library?
abstract contract TokenInput {

    function hashTokenInput(InputKind kind, address token, AddressExtended sender) public pure returns (uint256 hash) {
        TvmCell cell = abi.encode(kind, token, sender);
        return tvm.hash(cell);
    }

    function encodeTokenInputData(address sender, uint128 minAmount, uint128 minGas) public pure returns (TvmCell encoded) {
        return abi.encode(sender, minAmount, minGas);
    }

    function decodeTokenInputData(TvmCell params) public pure returns (TokenInputData data) {
        (AddressExtended sender, uint128 minAmount, uint128 minGas) = abi.decode(params, (AddressExtended, uint128, uint128));
        return TokenInputData(sender, minAmount, minGas);
    }

    function _checkTokenInput(TokenInputData data, address sender, uint128 amount, uint128 gas) internal pure {
        address expectedSender = ExtendedTypes.decodeAddressExtended(data.sender, sender);
        require(expectedSender == sender && amount >= data.minAmount && gas >= data.minGas, ErrorCodes.INVALID_INPUT);
    }

}
