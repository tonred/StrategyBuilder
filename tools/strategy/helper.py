import os

from tvmbase.abi.converter import file_to_abi
from tvmbase.client import Client
from tvmbase.constants import EMPTY_CELL
from tvmbase.models.network import NetworkFactory
from tvmbase.models.tvm.account import Account
from tvmbase.utils.to_ever import to_ever

from tools.strategy.models import AddressExtended, AmountExtended, InputKind, Command

EVERCLOUD_KEY = os.getenv('EVERCLOUD_KEY', '480fe4ee5f3e45ac85e6aa70505dc8dc')
BUILDER_ABI_FILENAME = '../../build/StrategyBuilder.abi.json'
STRATEGY_ABI_FILENAME = '../../build/Strategy.abi.json'

BUILDER_ADDRESS = '0:bfa6edc24504f7e40904c8e8d9a942bd385b256a78f0f45000ca7b61016014bf'
STRATEGY_ADDRESS = '0:2ddef82f0bd07ea5013c35f3fde096e3580cba2d9c157d1d241e5725345e654b'  # just for utils methods


class Helper:

    def __init__(self, client: Client, builder: Account, strategy: Account):
        self.client = client
        self.builder = builder
        self.strategy = strategy
        self.builder_abi = file_to_abi(BUILDER_ABI_FILENAME)
        self.strategy_abi = file_to_abi(STRATEGY_ABI_FILENAME)

    @classmethod
    async def create(cls):
        client = cls.create_client()
        builder = await Account.from_address(client, BUILDER_ADDRESS)
        strategy = await Account.from_address(client, STRATEGY_ADDRESS)
        return cls(client, builder, strategy)

    @staticmethod
    def create_client() -> Client:
        network_factory = NetworkFactory(EVERCLOUD_KEY)
        network = network_factory.mainnet()
        return Client(network)

    async def hash_token_input(self, kind: InputKind, token: str, sender: AddressExtended) -> str:
        return await self.client.run_local(self.strategy_abi, 'hashTokenInput', self.strategy, params={
            'kind': kind,
            'token': token,
            'sender': sender.dict(),
        }, parse=True)

    async def encode_token_input_data(self, token: str, min_amount: int, min_gas: int) -> str:
        return await self.client.run_local(self.strategy_abi, 'encodeTokenInputData', self.strategy, params={
            'token': token,
            'minAmount': min_amount,
            'minGas': min_gas,
        }, parse=True)

    async def encode_transfer_data(
            self,
            amount: AmountExtended,
            recipient: AddressExtended,
            is_deploy_wallet: bool = False,
            payload: str = EMPTY_CELL,
            value: int = to_ever(0.2),
            flag: int = 1,
    ) -> str:
        return await self.client.run_local(self.strategy_abi, 'encodeTransferActionData', self.strategy, params={
            'amount': amount.dict(),
            'recipient': recipient.dict(),
            'isDeployWallet': is_deploy_wallet,
            'payload': payload,
            'value': value,
            'flag': flag,
        }, parse=True)

    async def encode_swap_data(self, to: str, amount: AmountExtended, value: int, flag: int = 1) -> str:
        return await self.client.run_local(self.strategy_abi, 'encodeSwapActionData', self.strategy, params={
            'to': to,
            'amount': amount.dict(),
            'value': value,
            'flag': flag,
        }, parse=True)

    # address second, AmountExtended amount, address lp, uint128 value, uint8 flag
    async def encode_deposit_data(
            self,
            second: str,
            amount: AmountExtended,
            lp: str,
            value: int,
            flag: int = 1,
    ) -> str:
        return await self.client.run_local(self.strategy_abi, 'encodeDepositActionData', self.strategy, params={
            'second': second,
            'amount': amount.dict(),
            'lp': lp,
            'value': value,
            'flag': flag,
        }, parse=True)

    async def encode_farm_data(
            self,
            amount: AmountExtended,
            farm: str,
            deposit_owner: AddressExtended,
            lock_time: int,
            value: int,
            flag: int = 1,
    ) -> str:
        return await self.client.run_local(self.strategy_abi, 'encodeFarmActionData', self.strategy, params={
            'amount': amount.dict(),
            'farm': farm,
            'depositOwner': deposit_owner.dict(),
            'lockTime': lock_time,
            'value': value,
            'flag': flag,
        }, parse=True)

    @staticmethod
    def log_strategy(commands: dict[int, Command], inputs: dict[int, int], tokens_count: int):
        value = round(0.7 + 0.3 * tokens_count, 1)
        print(f'[DATA]:\n\towner: <owner>\n\tcommands:')
        for _id, command in commands.items():
            print(f'\t\t{_id}: {command.dict()}')
        print(f'\tinputs: {inputs}')
        print(f'[NONCE]: <nonce>')
        print(f'[msg.value]: {value}')
        print(f'Strategy Builder address: {BUILDER_ADDRESS}')
