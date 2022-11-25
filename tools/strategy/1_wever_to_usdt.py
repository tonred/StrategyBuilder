import asyncio

from tvmbase.constants import ZERO_ADDRESS
from tvmbase.utils.to_ever import to_ever

from tools.strategy.helper import Helper
from tools.strategy.models import (
    AmountExtendedKind, AmountExtended, AddressExtendedKind, AddressExtended, Command, CommandKind, InputKind
)


async def main():
    helper = await Helper.create()
    input_data = await helper.encode_token_input_data(min_amount=to_ever(0.1), min_gas=to_ever(2.2))
    wever_usdt = '0:771e3d124c7a824d341484718fcf1af03dd4ba1baf280adeb0663bb030ce2bf9'
    swap_data = await helper.encode_swap_data(
        amount=AmountExtended(AmountExtendedKind.PERCENT, helper.to_percent(1)),
        pair=wever_usdt,
        value=0,
        flag=128,
    )
    transfer_data = await helper.encode_transfer_data(
        amount=AmountExtended(AmountExtendedKind.PERCENT, helper.to_percent(1)),
        recipient=AddressExtended(AddressExtendedKind.SENDER, ZERO_ADDRESS),
        value=0,
        flag=128,
    )
    commands = {
        1: Command(CommandKind.EXIT, input_data, next_id=2),
        2: Command(CommandKind.SWAP, swap_data, child_id=3),
        3: Command(CommandKind.TRANSFER, transfer_data),
    }
    wever = '0:a49cd4e158a9a15555e624759e2e4e766d22600b7800d891e46f9291f044a93d'
    input_hash = await helper.hash_token_input(
        kind=InputKind.TOKEN,
        token=wever,
        sender=AddressExtended(AddressExtendedKind.SENDER, ZERO_ADDRESS),
    )
    inputs = {input_hash: 1}
    usdt = '0:a519f99bb5d6d51ef958ed24d337ad75a1c770885dcd42d51d6663f9fcdacfb2'
    tokens = [wever, usdt]
    print(f'[DATA]:\n\towner: <owner>\n\tcommands:')
    for _id, command in commands.items():
        print(f'\t\t{_id}: {command.dict()}')
    print(f'\tinputs: {inputs}')
    print(f'[TOKENS]: {tokens}')
    print(f'[NONCE]: <nonce>')
    print(f'[msg.value]: 1.1')


if __name__ == '__main__':
    asyncio.run(main())
