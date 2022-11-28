from dataclasses import dataclass
from enum import IntEnum


class AddressExtendedKind(IntEnum):
    VALUE = 0
    SENDER = 1
    OWNER = 2
    STRATEGY = 3


@dataclass(frozen=True, slots=True)
class AddressExtended:
    kind: AddressExtendedKind
    value: str

    def dict(self) -> dict:
        return {
            'kind': self.kind.value,
            'value': self.value,
        }


class AmountExtendedKind(IntEnum):
    VALUE = 0
    PERCENT = 1
    REMAINING = 2


@dataclass(frozen=True, slots=True)
class AmountExtended:
    kind: AmountExtendedKind
    value: int

    def dict(self) -> dict:
        return {
            'kind': self.kind.value,
            'value': self.value,
        }


class InputKind(IntEnum):
    TOKEN = 0
    RECEIVE = 1
    TRIGGER = 2


class CommandKind(IntEnum):
    INPUT = 0
    TRANSFER = 1
    SWAP = 2
    DEPOSIT = 3
    FARM = 4
    WRAP = 5
    UNWRAP = 6


@dataclass(frozen=True, slots=True)
class Command:
    kind: CommandKind
    params: str
    child_id: int = 0
    next_id: int = 0

    def dict(self) -> dict:
        return {
            'kind': self.kind.value,
            'params': self.params,
            'childID': self.child_id,
            'nextID': self.next_id,
        }
