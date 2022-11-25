pragma ever-solidity ^0.63.0;

import "../structures/ExecutionData.sol";
import "./Constants.sol";
import "./ErrorCodes.sol";


enum AddressExtendedKind {
    VALUE, SENDER, OWNER
}

struct AddressExtended {
    AddressExtendedKind kind;
    address value;
}

enum AmountExtendedKind {
    VALUE, PERCENT, REMAINING
}

struct AmountExtended {
    AmountExtendedKind kind;
    uint128 value;
}


library ExtendedTypes {

    function createAddressExtended(AddressExtendedKind kind, address value) public returns (AddressExtended extended) {
        if (kind != AddressExtendedKind.VALUE) {
            value = address(0);
        }
        return AddressExtended(kind, value);
    }

    function createAmountExtended(AmountExtendedKind kind, uint128 value) public returns (AmountExtended extended) {
        require(kind != AmountExtendedKind.REMAINING || value == 0, ErrorCodes.INVALID_EXTENDED_TYPE);
        return AmountExtended(kind, value);
    }

    function decodeAddressExtended(AddressExtended extended, address sender, address owner) public returns (address decoded) {
        AddressExtendedKind kind = extended.kind;
        if (kind == AddressExtendedKind.VALUE) {
            return extended.value;
        } else if (kind == AddressExtendedKind.SENDER) {
            return sender;
        } else if (kind == AddressExtendedKind.OWNER) {
            return owner;
        } else {
            revert(ErrorCodes.INVALID_EXTENDED_TYPE);
        }
    }

    function decodeAmountExtended(AmountExtended extended, ExecutionData data) public returns (uint128 decoded) {
        AmountExtendedKind kind = extended.kind;
        if (kind == AmountExtendedKind.VALUE) {
            return extended.value;
        } else if (kind == AmountExtendedKind.PERCENT) {
            uint128 value = math.muldiv(data.amount, extended.value, Constants.PERCENT_DENOMINATOR);
            return value;
        } else if (kind == AmountExtendedKind.REMAINING) {
            return (data.amount > data.spent) ? (data.amount - data.spent) : 0;
        } else {
            revert(ErrorCodes.INVALID_EXTENDED_TYPE);
        }
    }

}
