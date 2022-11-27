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
import "./interfaces/IOwner.sol";
import "./interfaces/external/FlatqubeDao.sol";
import "./utils/TransferUtils.sol";


contract Strategy is TransferAction, SwapAction, DepositAction, FarmAction, TokenInput, TransferUtils {

    event ChangedOwner(address oldOwner, address newOwner);
    event ExecuteCommand(uint32 id);
    event ExecuteInput(uint32 id);
    event ReturnTokens(address token);

    address public _root;
    address public _owner;
    mapping(uint32 /*id*/ => Command) public _commands;
    mapping(uint256 /*hash*/ => uint32 /*id*/) public _inputs;

    // in execute
    ExecutionData _executionData;


    modifier onlyOwner() {
        require(msg.sender == _owner, ErrorCodes.IS_NOT_OWNER);
        _;
    }


    function onCodeUpgrade(TvmCell input) internal {
        _reserve();
        tvm.resetStorage();
        (address root, TvmCell initialData, TvmCell initialParams) =
            abi.decode(input, (address, TvmCell, TvmCell));
        _root = root;
        uint64 nonce;
        (_owner, _commands, _inputs, nonce) =
            abi.decode(initialData, (address, mapping(uint32 => Command), mapping(uint256 => uint32), uint64));
        (address[] additionalTokens, address callbackTo) = abi.decode(initialParams, (address[], address));
        address[] tokens = extractTokens(additionalTokens);
        _createWallets(tokens);
        IOwner(callbackTo).onStrategyCreated{
            value: 0,
            flag: MsgFlag.ALL_NOT_RESERVED,
            bounce: false
        }(address(this), nonce);
    }

    function extractTokens(address[] additionalTokens) public view returns (address[] tokens) {
        mapping(address => bool) uniqueTokens;
        for (address token : additionalTokens) {
            uniqueTokens[token] = true;
        }
        for ((, Command command) : _commands) {
            CommandKind kind = command.kind;
            if (kind == CommandKind.SWAP) {
                address token = SwapAction.swapChildToken(command.params);
                uniqueTokens[token] = true;
            } else if (kind == CommandKind.DEPOSIT) {
                address token = DepositAction.depositChildToken(command.params);
                uniqueTokens[token] = true;
            }
        }
        for ((, uint32 id) : _inputs) {
            Command command = _getCommand(id);
            address token = TokenInput.tokenInputToken(command.params);
            uniqueTokens[token] = true;
        }
        return uniqueTokens.keys();
    }

    function changeOwner(address newOwner) public cashBack {
        if (_owner == newOwner) {
            return;
        }
        emit ChangedOwner(_owner, newOwner);
        _owner = newOwner;
    }

    function withdraw(address token, uint128 amount, bool force) public onlyOwner {
        _reserve();
        if (amount == 0) {
            amount = _balances[token];
        }
        _returnTokens(token, _owner, amount, force);
    }

    function drain() public onlyOwner cashBack {}

    function claim(address gauge, uint32 callID, uint32 nonce) public view onlyOwner minValue(Gas.MIN_CLAIM_VALUE) {
        IGaugeBase(gauge).claimReward{
            value: 0,
            flag: MsgFlag.REMAINING_GAS,
            bounce: false
        }(Callback.CallMeta(callID, nonce, msg.sender));
    }


    function onAcceptTokensTransfer(
        address token,
        uint128 amount,
        address sender,
        address /*senderWallet*/,
        address /*remainingGasTo*/,
        TvmCell payload
    ) public override {
        require(msg.sender == _wallets[token] && msg.sender.value != 0, ErrorCodes.IS_NOT_WALLET);
        _onTokenInput(token, amount, sender, payload);
    }

    function onAcceptTokensMint(
        address token,
        uint128 amount,
        address /*remainingGasTo*/,
        TvmCell payload
    ) public override {
        require(msg.sender == _wallets[token] && msg.sender.value != 0, ErrorCodes.IS_NOT_WALLET);
        _onTokenInput(token, amount, address(0), payload);
    }

    receive() external {
        _reserve();
        _onInput(InputKind.RECEIVE, address(0), msg.sender, msg.value, 0);
    }

    function trigger(uint128 amount) public {
        _reserve();
        if (msg.value < amount) {
            _returnTokens(address(0), msg.sender, 0, false);
            return;
        }
        _onInput(InputKind.TRIGGER, address(0), msg.sender, amount, msg.value - amount);
    }


    function _onTokenInput(address token, uint128 amount, address sender, TvmCell payload) private {
        _reserve();
        _balances[token] += amount;
        (bool hasCallData, CallData callData) = _decodeCallData(payload);
        if (hasCallData) {
            _check(callData, token, sender);
            _executionData = ExecutionData(callData, token, amount, 0);
            _execute();
        } else {
            _onInput(InputKind.TOKEN, token, sender, amount, msg.value);
        }
    }

    function _decodeCallData(TvmCell payload) private pure returns (bool, CallData) {
        if (!payload.toSlice().hasNBitsAndRefs(267 + 32 + 32, 0)) {
            return (false, CallData(address(0), 0, 0));
        }
        (address sender, uint32 parentID, uint32 childID) = abi.decode(payload, (address, uint32, uint32));
        return (true, CallData(sender, parentID, childID));
    }

    function _onInput(InputKind kind, address token, address sender, uint128 amount, uint128 gas) private {
        AddressExtended senderExtended = ExtendedTypes.createAddressExtended(AddressExtendedKind.VALUE, sender);
        uint256 hash = TokenInput.hashTokenInput(kind, token, senderExtended);
        if (!_inputs.exists(hash)) {
            AddressExtended anySender = ExtendedTypes.createAddressExtended(AddressExtendedKind.SENDER, address(0));
            hash = TokenInput.hashTokenInput(kind, token, anySender);
            if (!_inputs.exists(hash)) {
                _returnTokens(token, sender, amount, false);
                return;
            }
        }
        uint32 id = _inputs[hash];
        Command command = _getCommand(id);
        TokenInputData tokenInputData = TokenInput.decodeTokenInputData(command.params);
        if (!TokenInput._checkTokenInput(tokenInputData, token, amount, gas)) {
            _returnTokens(token, sender, amount, false);
            return;
        }
        emit ExecuteInput(id);
        CallData callData = CallData(sender, 0, command.nextID);
        _executionData = ExecutionData(callData, token, amount, 0);
        _execute();
    }

    function _check(CallData callData, address token, address sender) private view {
        Command command = _getCommand(callData.parentID);
        CommandKind kind = command.kind;
        if (kind == CommandKind.SWAP) {
            SwapAction._checkSwapResponse(sender);
        } else if (kind == CommandKind.DEPOSIT) {
            DepositAction._checkDepositResponse(command.params, token);
        } else {
            revert(ErrorCodes.INVALID_COMMAND);
        }
    }

    function _execute() private {
        do {
            uint32 id = _executionData.callData.childID;
            Command command = _getCommand(id);
            _executeOne(command);
            _executionData.callData.childID = command.nextID;
            emit ExecuteCommand(id);
        } while (_executionData.callData.childID != 0);
    }

    function _executeOne(Command command) private {
        CommandKind kind = command.kind;
        if (kind == CommandKind.NOTHING) {
            return;
        }
        if (kind == CommandKind.TRANSFER) {
            TransferActionData data = TransferAction.decodeTransferActionData(command.params, _executionData, _owner);
            _executionData.spent += data.amount;
            _transfer(data);
        } else if (kind == CommandKind.SWAP) {
            SwapActionData data = SwapAction.decodeSwapActionData(command.params, _executionData);
            _executionData.spent += data.amount;
            TvmCell meta = _encodeNextCallData(command);
            _swap(data, meta);
        } else if (kind == CommandKind.DEPOSIT) {
            DepositActionData data = DepositAction.decodeDepositActionData(command.params, _executionData);
            _executionData.spent += data.amount;
            TvmCell meta = _encodeNextCallData(command);
            _deposit(data, meta);
        } else if (kind == CommandKind.FARM) {
            FarmActionData data = FarmAction.decodeFarmActionData(command.params, _executionData, _owner);
            _executionData.spent += data.amount;
            _farm(data);
        }
    }

    function _encodeNextCallData(Command command) private view inline returns (TvmCell) {
        CallData nextCallData = CallData({
            sender: _executionData.callData.sender,
            parentID: _executionData.callData.childID,
            childID: command.childID
        });
        return abi.encode(nextCallData);
    }

    function _getCommand(uint32 id) private view inline returns (Command) {
        require(_commands.exists(id), ErrorCodes.INVALID_COMMAND);
        return _commands[id];
    }

    function _returnTokens(address token, address sender, uint128 amount, bool force) private {
        emit ReturnTokens(token);
        if (token.value == 0) {
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
                force: force
            }));
        }
    }

    function _targetBalance() internal view inline override returns (uint128) {
        return Gas.STRATEGY_TARGET_BALANCE;
    }

}
