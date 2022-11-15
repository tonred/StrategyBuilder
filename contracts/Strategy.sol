pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./commands/actions/Deposit.sol";
import "./commands/actions/Farm.sol";
import "./commands/actions/Swap.sol";
import "./commands/actions/Transfer.sol";
import "./commands/inputs/TokenInput.sol";
import "./commands/Command.sol";
import "./utils/TransferUtils.sol";


contract Strategy is TransferAction, SwapAction, DepositAction, FarmAction, TransferUtils {

    event ChangedOwner(address oldOwner, address newOwner);
    event ExecuteCommand(uint32 id);
    event ExecuteInput(uint32 id);
    event ReturnTokens();

    address public _root;
    address public _owner;
    mapping(uint32 /*id*/ => Command) public _commands;
    mapping(uint256 /*hash*/ => uint32 /*id*/) public _inputs;


    function onCodeUpgrade(TvmCell input, bool upgrade) internal {
        if (!upgrade) {
            tvm.resetStorage();
            (address root, TvmCell initialData, TvmCell initialParams) =
                abi.decode(input, (address, TvmCell, TvmCell));
            _root = root;
            (_owner, _commands, _inputs) =
                abi.decode(initialData, (address, mapping(uint32 => Command), mapping(uint256 => uint32)));
            address[] tokens = abi.decode(initialParams, address[]);
            _createWallets(tokens);
        } else {
            // todo versions
            // revert(VersionableErrorCodes.INVALID_OLD_VERSION);
        }
    }

    function _checkStrategy() private view {
        require(!_commands.empty() && !_commands.exists(0), ErrorCodes.INVALID_INPUT);
        for ((, uint32 id) : _inputs) {
            require(_commands.exists(id), ErrorCodes.INVALID_INPUT);
        }
    }

    function changeOwner(address newOwner) public cashBack {
        if (_owner == newOwner) {
            return;
        }
        emit ChangedOwner(_owner, newOwner);
        _owner = newOwner;
    }


    function onAcceptTokensTransfer(
        address token,
        uint128 amount,
        address sender,
        address /*senderWallet*/,
        address /*remainingGasTo*/,
        TvmCell payload
    ) public override {
        _reserve();
        _balances[token] += amount;
        // todo try-catch
        (bool hasCallData, CallData callData) = _decodeCallData(payload);
        if (hasCallData) {
            _check(callData);
            ExecutionData executionData = ExecutionData(callData, amount, 0);
            _execute(executionData);
        } else {
            _onInput(InputKind.TOKEN, token, sender, amount, msg.value);
        }
    }

    function onAcceptTokensMint(
        address token,
        uint128 amount,
        address /*remainingGasTo*/,
        TvmCell payload
    ) public override {
        _reserve();
        _balances[token] += amount;
        (bool hasCallData, CallData callData) = _decodeCallData(payload);
        if (hasCallData) {
            _check(callData);
            ExecutionData executionData = ExecutionData(callData, amount, 0);
            _execute(executionData);
        }
    }

    receive() external {
        _reserve();
        _onInput(InputKind.RECEIVE, address.makeAddrNone(), msg.sender, msg.value, 0);
    }

    function trigger(uint128 amount) public {
        _reserve();
        require(msg.value >= amount, ErrorCodes.INVALID_INPUT);
        _onInput(InputKind.TRIGGER, address.makeAddrNone(), msg.sender, amount, msg.value - amount);
    }


    function _decodeCallData(TvmCell payload) private pure returns (bool, CallData) {
        if (!payload.toSlice().hasNBitsAndRefs(267 + 32 + 32, 0)) {
            return (false, CallData(address(0), 0, 0));
        }
        (address sender, uint32 parentID, uint32 childID) = abi.decode(payload, (address, uint32, uint32));
        return (true, CallData(sender, parentID, childID));
    }

    function _onInput(InputKind kind, address token, address sender, uint128 amount, uint128 gas) private {
        uint256 hash = TokenInput.hashTokenInput(kind, token, AddressExtended(sender));
        if (!_inputs.exists(hash)) {
            AddressExtended anySender = ExtendedTypes.createAddressExtended(null);
            hash = TokenInput.hashTokenInput(kind, token, anySender);
            if (!_inputs.exists(hash)) {
                // todo try-catch ?
//                revert(ErrorCodes.INVALID_INPUT);
                _returnTokens(token, sender, amount);
                return;
            }
        }
        uint32 id = _inputs[hash];
        Command command = _getCommand(id);
        TokenInputData tokenInputData = TokenInput.decodeTokenInputData(command.params);
        TokenInput._checkTokenInput(tokenInputData, sender, amount, gas);
        emit ExecuteInput(id);
        CallData callData = CallData(sender, 0, command.nextID);
        ExecutionData executionData = ExecutionData(callData, amount, 0);
        _execute(executionData);
    }

    function _check(CallData callData) private view {
        Command command = _getCommand(callData.parentID);
        CommandKind kind = command.kind;
        if (kind == CommandKind.SWAP) {
            SwapAction._checkSwapResponse(command.params);
        } else if (kind == CommandKind.DEPOSIT) {
            DepositAction._checkDepositResponse(command.params);
        } else {
            revert(ErrorCodes.INVALID_COMMAND);
        }
    }

    function _execute(ExecutionData executionData) private {
        do {
            uint32 id = executionData.callData.childID;
            Command command = _getCommand(id);
            _executeOne(command, executionData);
            executionData.callData.childID = command.nextID;
            emit ExecuteCommand(id);
        } while (executionData.callData.childID != 0);
    }

    function _executeOne(Command command, ExecutionData executionData) private {
        CommandKind kind = command.kind;
        if (kind == CommandKind.EXIT) {
            return;
        }
        if (kind == CommandKind.TRANSFER) {
            TransferActionData data = TransferAction.decodeTransferActionData(command.params, executionData);
            _transfer(data);
        } else if (kind == CommandKind.SWAP) {
            SwapActionData data = SwapAction.decodeSwapActionData(command.params, executionData);
            TvmCell meta = _encodeNextCallData(command, executionData.callData);
            _swap(data, meta);
        } else if (kind == CommandKind.DEPOSIT) {
            DepositActionData data = DepositAction.decodeDepositActionData(command.params, executionData);
            TvmCell meta = _encodeNextCallData(command, executionData.callData);
            _deposit(data, meta);
        } else if (kind == CommandKind.FARM) {
            FarmActionData data = FarmAction.decodeFarmActionData(command.params, executionData);
            _farm(data);
        }
    }

    function _encodeNextCallData(Command command, CallData callData) private pure inline returns (TvmCell) {
        CallData nextCallData = CallData({
            sender: callData.sender,
            parentID: callData.childID,
            childID: command.childID
        });
        return abi.encode(nextCallData);
    }

    function _getCommand(uint32 id) private view inline returns (Command) {
        require(_commands.exists(id), ErrorCodes.INVALID_COMMAND);
        return _commands[id];
    }

    function _returnTokens(address token, address sender, uint128 amount) private {
        emit ReturnTokens();
        if (token.isNone()) {
            sender.transfer({value: 0, flag: MsgFlag.ALL_NOT_RESERVED, bounce: false});
        } else {
            TvmCell empty;
            _transfer(TransferActionData({
                token: token,
                amount: amount,
                recipient: sender,
                isDeployWallet: false,
                remainingGasTo: sender,
                payload: empty,
                value: 0,
                flag: MsgFlag.ALL_NOT_RESERVED,
                force: false
            }));
        }
    }

    function _targetBalance() internal view inline override returns (uint128) {
        return Gas.STRATEGY_TARGET_BALANCE;
    }

}
