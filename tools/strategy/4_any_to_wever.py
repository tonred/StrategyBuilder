import asyncio

from tvmbase.constants import ZERO_ADDRESS
from tvmbase.utils.to_ever import to_ever

from tools.strategy.helper import Helper
from tools.strategy.models import (
    AmountExtendedKind, AmountExtended, AddressExtendedKind, AddressExtended, Command, CommandKind, InputKind
)


async def main():
    wever = '0:a49cd4e158a9a15555e624759e2e4e766d22600b7800d891e46f9291f044a93d'
    tokens = [
        '0:a519f99bb5d6d51ef958ed24d337ad75a1c770885dcd42d51d6663f9fcdacfb2',  # usdt
        '0:c37b3fafca5bf7d3704b081fde7df54f298736ee059bf6d32fac25f5e6085bf6',  # usdc
        '0:f2679d80b682974e065e03bf42bbee285ce7c587eb153b41d761ebfd954c45e1',  # bridge
        '0:9f20666ce123602fd7a995508aeaa0ece4f92133503c0dfbd609b3239f3901e2',  # qube
        '0:2ba32b75870d572e255809b7b423f30f36dd5dea075bd5f026863fceb81f2bcf',  # wbtc
        '0:59b6b64ac6798aacf385ae9910008a525a84fc6dcf9f942ae81f8e8485fe160d',  # weth
        '0:eb2ccad2020d9af9cec137d3146dde067039965c13a27d97293c931dae22b2b9',  # dai
        '0:9d49206b0eaadc5125c6b5e30410505db7740f827857915922cdb7efe199b622',  # purr
    ]
    helper = await Helper.create()
    swap_data = await helper.encode_swap_data(
        to=wever,
        amount=AmountExtended(AmountExtendedKind.REMAINING, 0),
        value=0,
        flag=128,
    )
    transfer_data = await helper.encode_transfer_data(
        amount=AmountExtended(AmountExtendedKind.REMAINING, 0),
        recipient=AddressExtended(AddressExtendedKind.SENDER, ZERO_ADDRESS),
        value=0,
        flag=128,
    )
    commands = {
        1: Command(CommandKind.SWAP, swap_data, child_id=2),
        2: Command(CommandKind.TRANSFER, transfer_data),
    }
    inputs = dict()
    for index, token in enumerate(tokens, start=3):
        input_data = await helper.encode_token_input_data(token, min_amount=10, min_gas=to_ever(2.2))
        commands[index] = Command(CommandKind.INPUT, input_data, next_id=1)
        input_hash = await helper.hash_token_input(
            kind=InputKind.TOKEN,
            token=token,
            sender=AddressExtended(AddressExtendedKind.SENDER, ZERO_ADDRESS),
        )
        inputs[input_hash] = index
    helper.log_strategy(commands, inputs, tokens_count=len(tokens) + 1)


if __name__ == '__main__':
    asyncio.run(main())
