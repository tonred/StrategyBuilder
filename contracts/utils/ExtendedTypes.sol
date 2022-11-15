pragma ever-solidity ^0.63.0;

import "../structures/ExecutionData.sol";
import "./Constants.sol";
import "./ErrorCodes.sol";


struct AddressExtended {
    address value;  // address.makeAddrNone() in case of `SENDER`
}

enum AmountExtendedKind {
    VALUE, PERCENT, REMAINING
}

struct AmountExtended {
    AmountExtendedKind kind;
    uint128 value;
}


library ExtendedTypes {

    function createAddressExtended(optional(address) value) public returns (AddressExtended extended) {
        return value.hasValue() ? AddressExtended(value.get()) : AddressExtended(address.makeAddrNone());
    }

    function createAmountExtended(AmountExtendedKind kind, uint128 value) public returns (AmountExtended extended) {
        require(kind != AmountExtendedKind.REMAINING || value == 0, ErrorCodes.INVALID_EXTENDED_TYPE);
        return AmountExtended(kind, value);
    }

    function decodeAddressExtended(AddressExtended extended, address sender) public returns (address decoded) {
        if (extended.value.isNone()) {
            return sender;
        } else {
            return extended.value;
        }
    }

    function decodeAmountExtended(AmountExtended extended, ExecutionData data) public returns (uint128 decoded) {
        if (extended.kind == AmountExtendedKind.VALUE) {
            return extended.value;
        } else if (extended.kind == AmountExtendedKind.PERCENT) {
            uint128 value = math.muldiv(data.total, extended.value, Constants.PERCENT_DENOMINATOR);
            data.spent += value;
            return value;
        } else if (extended.kind == AmountExtendedKind.REMAINING) {
            return (data.total > data.spent) ? (data.total - data.spent) : 0;
        } else {
            revert(ErrorCodes.INVALID_EXTENDED_TYPE);
        }
    }

}
