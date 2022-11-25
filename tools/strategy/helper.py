import os

from tvmbase.abi.converter import file_to_abi
from tvmbase.client import Client
from tvmbase.constants import EMPTY_CELL, HALF_EVER
from tvmbase.models.network import NetworkFactory
from tvmbase.models.tvm.account import Account

from tools.strategy.models import AddressExtended, AmountExtended, InputKind

PERCENT_DENOMINATOR = 100_000

EVERCLOUD_KEY = os.getenv('EVERCLOUD_KEY', '480fe4ee5f3e45ac85e6aa70505dc8dc')
BUILDER_ABI_FILENAME = '../../build/StrategyBuilder.abi.json'
STRATEGY_ABI_FILENAME = '../../build/Strategy.abi.json'

BUILDER_ADDRESS = '0:0b0dd0d6f46bcc689e735b991b226ac90916f88ffc4c551b5461fda65b90bbf3'
SAMPLE_STRATEGY_ADDRESS = '0:ef94feb716c5ffef614d29c8de44bc4ce9e66e50baa6f229eab949d3b8154500'


class Helper:

    def __init__(self, client: Client, builder: Account, sample_strategy: Account):
        self.client = client
        self.builder = builder
        self.sample_strategy = sample_strategy
        self.builder_abi = file_to_abi(BUILDER_ABI_FILENAME)
        self.strategy_abi = file_to_abi(STRATEGY_ABI_FILENAME)

    @classmethod
    async def create(cls):
        client = cls.create_client()
        builder = await Account.from_address(client, BUILDER_ADDRESS)
        sample_strategy = await Account.from_address(client, SAMPLE_STRATEGY_ADDRESS)
        return cls(client, builder, sample_strategy)

    @staticmethod
    def create_client() -> Client:
        network_factory = NetworkFactory(EVERCLOUD_KEY)
        network = network_factory.mainnet()
        return Client(network)

    async def hash_token_input(self, kind: InputKind, token: str, sender: AddressExtended) -> str:
        return await self.client.run_local(self.strategy_abi, 'hashTokenInput', self.sample_strategy, params={
            'kind': kind,
            'token': token,
            'sender': sender.dict(),
        }, parse=True)

    async def encode_token_input_data(self, min_amount: int, min_gas: int) -> str:
        return await self.client.run_local(self.strategy_abi, 'encodeTokenInputData', self.sample_strategy, params={
            'minAmount': min_amount,
            'minGas': min_gas,
        }, parse=True)

    async def encode_swap_data(self, amount: AmountExtended, pair: str, value: int, flag: int = 1) -> str:
        return await self.client.run_local(self.strategy_abi, 'encodeSwapActionData', self.sample_strategy, params={
            'amount': amount.dict(),
            'pair': pair,
            'value': value,
            'flag': flag,
        }, parse=True)

    async def encode_transfer_data(
            self,
            amount: AmountExtended,
            recipient: AddressExtended,
            is_deploy_wallet: bool = False,
            payload: str = EMPTY_CELL,
            value: int = HALF_EVER,
            flag: int = 1,
    ) -> str:
        return await self.client.run_local(
            abi=self.strategy_abi,
            method='encodeTransferActionData',
            account=self.sample_strategy,
            params={
                'amount': amount.dict(),
                'recipient': recipient.dict(),
                'isDeployWallet': is_deploy_wallet,
                'payload': payload,
                'value': value,
                'flag': flag,
            },
            parse=True,
        )

    @staticmethod
    def to_percent(percent: float) -> int:
        return int(percent * PERCENT_DENOMINATOR)
