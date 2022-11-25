import asyncio

from tvmbase.constants import ZERO_ADDRESS
from tvmbase.utils.to_ever import to_ever

from tools.strategy.helper import Helper
from tools.strategy.models import (
    AmountExtendedKind, AmountExtended, AddressExtendedKind, AddressExtended, Command, CommandKind, InputKind
)


async def main():
    wever = '0:a49cd4e158a9a15555e624759e2e4e766d22600b7800d891e46f9291f044a93d'
    usdt = '0:a519f99bb5d6d51ef958ed24d337ad75a1c770885dcd42d51d6663f9fcdacfb2'
    wever_usdt_lp = '0:c4faf70154a6d885bdc5856df54b9a3507eb4a98681e9902fdefc369bbb9d7b9'
    farm = '0:eab26e9b6834dfbd2eff9411c7f62c217fd9c8219ee062196b4a854a702acbdb'
    lock_time = 60 * 60 * 24 * 30  # 30 days
    helper = await Helper.create()
    input_data = await helper.encode_token_input_data(wever, min_amount=to_ever(0.1), min_gas=to_ever(2.2))
    fee_data = await helper.encode_transfer_data(
        amount=AmountExtended(AmountExtendedKind.PERCENT, helper.to_percent(0.05)),  # 5% fee
        recipient=AddressExtended(AddressExtendedKind.OWNER, ZERO_ADDRESS),
        value=to_ever(0.2),
        flag=1,
    )
    deposit_data = await helper.encode_deposit_data(
        second=usdt,
        amount=AmountExtended(AmountExtendedKind.REMAINING, 0),
        lp=wever_usdt_lp,
        value=0,
        flag=128,
    )
    farm_data = await helper.encode_farm_data(
        amount=AmountExtended(AmountExtendedKind.PERCENT, helper.to_percent(1)),
        farm=farm,
        deposit_owner=AddressExtended(AddressExtendedKind.SENDER, ZERO_ADDRESS),
        lock_time=lock_time,
        value=0,
        flag=128,
    )
    commands = {
        1: Command(CommandKind.EXIT, input_data, next_id=2),
        2: Command(CommandKind.TRANSFER, fee_data, next_id=3),
        3: Command(CommandKind.DEPOSIT, deposit_data, child_id=4),
        4: Command(CommandKind.FARM, farm_data),
    }
    input_hash = await helper.hash_token_input(
        kind=InputKind.TOKEN,
        token=wever,
        sender=AddressExtended(AddressExtendedKind.SENDER, ZERO_ADDRESS),
    )
    inputs = {input_hash: 1}
    helper.log_strategy(commands, inputs, tokens_count=2)


if __name__ == '__main__':
    asyncio.run(main())
