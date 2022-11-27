import asyncio

from tvmbase.constants import ZERO_ADDRESS
from tvmbase.utils.to_ever import to_ever

from tools.strategy.helper import Helper
from tools.strategy.models import (
    AmountExtendedKind, AmountExtended, AddressExtendedKind, AddressExtended, Command, CommandKind, InputKind
)
from tools.strategy.utils import to_percent, to_seconds


async def main():
    any_to_wever_strategy = '0:7e4d84423acf3121b42113d669fc87be010ff3926d0ba007874663e53a912197'
    fee_collector = '0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e'
    wever = '0:a49cd4e158a9a15555e624759e2e4e766d22600b7800d891e46f9291f044a93d'
    bridge = '0:f2679d80b682974e065e03bf42bbee285ce7c587eb153b41d761ebfd954c45e1'
    wever_bridge_lp = '0:5c66f770d439212181bb6f62714bc235f754653ad9e2aca5a685ff7979174ea2'
    farm = '0:6b6b773fc6f08567f6639482f2584a50f4af1998ebec98d506b2bbb58f1c6d2f'
    lock_time = to_seconds(days=30)
    tokens = [
        '0:a519f99bb5d6d51ef958ed24d337ad75a1c770885dcd42d51d6663f9fcdacfb2',  # usdt
        '0:c37b3fafca5bf7d3704b081fde7df54f298736ee059bf6d32fac25f5e6085bf6',  # usdc
    ]
    helper = await Helper.create()
    any_to_wever_data = await helper.encode_transfer_data(
        amount=AmountExtended(AmountExtendedKind.REMAINING, 0),
        recipient=AddressExtended(AddressExtendedKind.VALUE, any_to_wever_strategy),
        value=0,
        flag=128,
    )
    fee_data = await helper.encode_transfer_data(
        amount=AmountExtended(AmountExtendedKind.PERCENT, to_percent(0.05)),  # 5% fee
        recipient=AddressExtended(AddressExtendedKind.VALUE, fee_collector),
        value=to_ever(0.2),
        flag=1,
    )
    deposit_data = await helper.encode_deposit_data(
        second=bridge,
        amount=AmountExtended(AmountExtendedKind.REMAINING, 0),
        lp=wever_bridge_lp,
        value=0,
        flag=128,
    )
    farm_data = await helper.encode_farm_data(
        amount=AmountExtended(AmountExtendedKind.PERCENT, to_percent(1)),
        farm=farm,
        deposit_owner=AddressExtended(AddressExtendedKind.STRATEGY, ZERO_ADDRESS),
        lock_time=lock_time,
        value=0,
        flag=128,
    )
    wever_input_data = await helper.encode_token_input_data(wever, min_amount=10, min_gas=to_ever(8.9))
    commands = {
        1: Command(CommandKind.TRANSFER, any_to_wever_data),
        2: Command(CommandKind.NOTHING, wever_input_data, next_id=3),
        3: Command(CommandKind.TRANSFER, fee_data, next_id=4),
        4: Command(CommandKind.DEPOSIT, deposit_data, child_id=5),
        5: Command(CommandKind.FARM, farm_data),
    }
    input_hash = await helper.hash_token_input(
        kind=InputKind.TOKEN,
        token=wever,
        sender=AddressExtended(AddressExtendedKind.SENDER, ZERO_ADDRESS),
    )
    inputs = {input_hash: 2}
    for index, token in enumerate(tokens, start=6):
        input_data = await helper.encode_token_input_data(token, min_amount=100, min_gas=to_ever(9.4))
        commands[index] = Command(CommandKind.NOTHING, input_data, next_id=1)
        input_hash = await helper.hash_token_input(
            kind=InputKind.TOKEN,
            token=token,
            sender=AddressExtended(AddressExtendedKind.SENDER, ZERO_ADDRESS),
        )
        print(token, input_hash)
        inputs[input_hash] = index
    helper.log_strategy(commands, inputs, tokens_count=len(tokens) + 2)


if __name__ == '__main__':
    asyncio.run(main())
