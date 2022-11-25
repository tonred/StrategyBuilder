/*
Command         Action.Farm
Description     Deposit lp tokens to farming
Parents         1
Childs          0
Target          https://github.com/broxus/flatqube-dao-contracts/blob/master/contracts/gauge/base/gauge/GaugeBase.sol#L18

*/

pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./Transfer.sol";


struct FarmActionData {
    address token;
    uint128 amount;
    address farm;
    address remainingGasTo;
    address depositOwner;
    uint32 lockTime;
    uint128 value;
    uint8 flag;
}


abstract contract FarmAction is TransferAction {

    function encodeFarmActionData(
        AmountExtended amount, address farm, AddressExtended depositOwner, uint32 lockTime, uint128 value, uint8 flag
    ) public pure returns (TvmCell encoded) {
        return abi.encode(amount, farm, depositOwner, lockTime, value, flag);
    }

    function decodeFarmActionData(TvmCell params, ExecutionData data, address owner) public pure returns (FarmActionData decoded) {
        (AmountExtended amount, address farm, AddressExtended depositOwner, uint32 lockTime, uint128 value, uint8 flag) =
            abi.decode(params, (AmountExtended, address, AddressExtended, uint32, uint128, uint8));
        address sender = data.callData.sender;
        uint128 amountDecoded = ExtendedTypes.decodeAmountExtended(amount, data);
        address depositOwnerDecoded = ExtendedTypes.decodeAddressExtended(depositOwner, sender, owner);
        return FarmActionData(data.token, amountDecoded, farm, sender, depositOwnerDecoded, lockTime, value, flag);
    }

    function _farm(FarmActionData data) internal {
        TvmCell payload = _buildFarmPayload(data.depositOwner, data.lockTime);
        _transfer(TransferActionData({
            token: data.token,
            amount: data.amount,
            recipient: data.farm,
            isDeployWallet: false,
            remainingGasTo: data.remainingGasTo,
            payload: payload,
            value: data.value,
            flag: data.flag,
            force: false
        }));
    }

    function _buildFarmPayload(address depositOwner, uint32 lockTime) private pure returns (TvmCell) {
        TvmBuilder builder;
        builder.store(depositOwner);    // deposit owner
        builder.store(lockTime);        // lock time
        builder.store(false);           // can claim
        builder.store(uint32(0));       // id
        builder.store(uint32(0));       // nonce
        return builder.toCell();
    }

}
