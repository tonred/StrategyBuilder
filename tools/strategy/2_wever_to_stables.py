import asyncio

from tvmbase.constants import ZERO_ADDRESS
from tvmbase.utils.to_ever import to_ever

from tools.strategy.helper import Helper
from tools.strategy.models import (
    AmountExtendedKind, AmountExtended, AddressExtendedKind, AddressExtended, Command, CommandKind, InputKind
)
from tools.strategy.utils import to_percent


async def main():
    wever = '0:a49cd4e158a9a15555e624759e2e4e766d22600b7800d891e46f9291f044a93d'
    usdt = '0:a519f99bb5d6d51ef958ed24d337ad75a1c770885dcd42d51d6663f9fcdacfb2'
    usdc = '0:c37b3fafca5bf7d3704b081fde7df54f298736ee059bf6d32fac25f5e6085bf6'
    dai = '0:eb2ccad2020d9af9cec137d3146dde067039965c13a27d97293c931dae22b2b9'
    helper = await Helper.create()
    input_data = await helper.encode_token_input_data(wever, min_amount=to_ever(0.1), min_gas=to_ever(6.9))
    usdt_swap_data = await helper.encode_swap_data(
        to=usdt,
        amount=AmountExtended(AmountExtendedKind.PERCENT, to_percent(0.33333)),
        value=to_ever(2.2),
        flag=1,
    )
    usdc_swap_data = await helper.encode_swap_data(
        to=usdc,
        amount=AmountExtended(AmountExtendedKind.PERCENT, to_percent(0.33333)),
        value=to_ever(2.2),
        flag=1,
    )
    dai_swap_data = await helper.encode_swap_data(
        to=dai,
        amount=AmountExtended(AmountExtendedKind.REMAINING, 0),
        value=0,
        flag=128,
    )
    transfer_data = await helper.encode_transfer_data(
        amount=AmountExtended(AmountExtendedKind.PERCENT, to_percent(1)),
        recipient=AddressExtended(AddressExtendedKind.SENDER, ZERO_ADDRESS),
        is_deploy_wallet=True,
        value=0,
        flag=128,
    )
    commands = {
        1: Command(CommandKind.INPUT, input_data, next_id=2),
        2: Command(CommandKind.SWAP, usdt_swap_data, child_id=5, next_id=3),
        3: Command(CommandKind.SWAP, usdc_swap_data, child_id=5, next_id=4),
        4: Command(CommandKind.SWAP, dai_swap_data, child_id=5),
        5: Command(CommandKind.TRANSFER, transfer_data),
    }
    input_hash = await helper.hash_token_input(
        kind=InputKind.TOKEN,
        token=wever,
        sender=AddressExtended(AddressExtendedKind.SENDER, ZERO_ADDRESS),
    )
    inputs = {input_hash: 1}
    helper.log_strategy(commands, inputs, tokens_count=4)


if __name__ == '__main__':
    asyncio.run(main())
