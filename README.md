# Strategy Builder

Project Github: https://github.com/tonred/StrategyBuilder

MainNet Strategy Builder: `0:bfa6edc24504f7e40904c8e8d9a942bd385b256a78f0f45000ca7b61016014bf`

UI Builder and Viewer: [https://strategy-builder-front.pages.dev](https://strategy-builder-front.pages.dev)

TG: @Abionics, @get_username

## Key features:
* Easy to build using ready components
* Flexible configuration
* Auto-setup wallets and utils in Strategy
* User-friendly UI builder
* Ability to extend builder with new commands


## Technical description

### Abstract

Project contains 2 contract types: Strategy and StrategyBuilder.
StrategyBuilder is used for Strategy creation and validation.
Strategy is the main entity which contains all info about workflow,
token inputs, wallets etc

Strategy workflow is described as DAG ([Directed Acyclic Graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph))
where roots (inputs) is a token inputs. There is a sample with 2 inputs (USDT/USDC)
![Sample DAG](docs/sample-dag.png)
Every leaf (block) in DAG tree is a separate command, see [Command](#Command) for details.
In addition, inputs have additional hash mapping in order to detect different tokens as different inputs,
see [Input](#Input) for details.

### Command

Every command contains:
* Command kind (see [Supported commands](#Supported-Commands))
* Specific command params
* [optional] ID of child command that will be executed in callback of current command (for example, transfer **after** swap)
* [optional] ID of next command that will be executed next in this transaction (for example, 2 swaps **in a row**)

[//]: # (todo)

### Supported Commands

| kind       | childID | description and params                                                                                                  | code                                                    |
|------------|---------|-------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------|
| `NOTHING`  | -       | Empty command, can be used for empty callback (exit) or as a mock in `TokenInput`                                       | -                                                       |
| `TRANSFER` | +       | Transfer TIP3 token to recipient <br> **Params:** amount, recipient, isDeployWallet, payload, value (send), flag (send) | [Transfer.sol](contracts/commands/actions/Transfer.sol) |
| `SWAP`     | -       | Swap token in pair <br> **Params:** to (token root), amount, value (send), flag (send)                                  | [Swap.sol](contracts/commands/actions/Swap.sol)         |
| `DEPOSIT`  | +       | Deposit liquidity to pool <br> **Params:** second (token root), amount, lp (token root), value (send), flag (send)      | [Deposit.sol](contracts/commands/actions/Deposit.sol)   |
| `FARM`     | -       | Deposit lp tokens to farming <br> **Params:** amount, farm, depositOwner, lockTime, value (send), flag (send)           | [Farm.sol](contracts/commands/actions/Farm.sol)         |

**Strategy can be connected to each other.** This can be done via just sending tokens
to an address of another strategy (and accepting callback token(s) as inputs if needed).
See more in [Sample Strategies](#Sample-Strategies)

All commands source code files have more details in headers.
New command type can be easily added to Strategy, because all commands have similar interface.
Examples of commands that we did not implemented due to lack of time:
* Wrap ever to wever (see template in [unused/Wrap.sol](contracts/commands/actions/unused/Wrap.sol))
* Unwrap wever to ever (see template in [unused/Unwrap.sol](contracts/commands/actions/unused/Unwrap.sol))
* Send tokens via Octus Bridge

### Input

In order to detect different token inputs, every input has unique hash. This hash contains from
token input kind, token root address and allowed sender address (use `AddressExtendedKind.SENDER` kind for any sender).
Currently supported token input kinds:
* `InputKind.TOKEN` - on TIP3.1 token input
* `InputKind.RECEIVE` - on evers receiving
* `InputKind.TRIGGER` - on calling `Strategy.trigger()` method via internal message

The most useful token input kinds is a `InputKind.TOKEN`

## Additional Functions

Each Strategy has set of methods that can be called only by owner. It is:
* `drain` - drain redundant evers
* `withdraw(token, amount, force)` - withdraw TIP3.1 token from Strategy wallet.
Force used in order to skip balance checks in contract (in case of unexpected balance)
* `claim(gauge, callID, nonce)` - claim reward from Strategy account in Gauge farming
* `changeOwner(newOwner` - change owner of Strategy


## Deploy

### Requirements

* [locklift](https://www.npmjs.com/package/locklift) `1.5.3`
* [everdev](https://github.com/tonlabs/everdev) with compiler `0.63.0`, linker `0.15.70`
* python `3.10`
* nodejs

### Deploy

1) Setup

```shell
npm run setup
```

2) Build

```shell
npm run build
```

3) Deploy

```shell
npm run deploy-builder
```


## Builder tools

[//]: # (todo link)
There is UI for viewing and building strategies.
You can insert any created strategy in (todo link)
to view it DAG

Moreover, there is simple Python tool for strategy building in [tools/strategy](tools/strategy).
Dot forget to install [requirements.txt](tools/requirements.txt) before.
It already contains 5 sample strategy, that is describes in [Sample Strategies](#Sample-Strategies)


## Sample Strategies

### Swap WEVER to USDT

MainNet address: `0:2ddef82f0bd07ea5013c35f3fde096e3580cba2d9c157d1d241e5725345e654b`

UI viewer link: [https://strategy-builder-front.pages.dev/strategy/0:2ddef82f0bd07ea5013c35f3fde096e3580cba2d9c157d1d241e5725345e654b](https://strategy-builder-front.pages.dev/strategy/0:2ddef82f0bd07ea5013c35f3fde096e3580cba2d9c157d1d241e5725345e654b)

![Sample Strategy 1](docs/sample-strategy-1.png)

This is a simple Strategy that swap any amount WEVER to USDT and send them back to sender.
It is a pipeline "receive token + swap a preconfigured portion of them + optionally send to preconfigured recipient address" from challenge

### Swap to 3 stables

[//]: # (todo)
MainNet address: ``

[//]: # (todo)
UI viewer link: []()

![Sample Strategy 2](docs/sample-strategy-2.png)

This Strategy swap any amount WEVER to USDT + USDC + DAI in equal proportion (33.3%).
It is a pipeline "receive token + swap to multiple tokens according to configuration + withdraw method" from challenge.
By the way, withdraw method is also implemented, see [Additional Functions](#Additional-Functions)

### Deposit and farm

MainNet address: `0:dcdfdeaefca1c1d189a61317ce4b97f21fd6c7f73a6c9b25ddf68e16cfa2ecc4`

UI viewer link: [https://strategy-builder-front.pages.dev/strategy/0:dcdfdeaefca1c1d189a61317ce4b97f21fd6c7f73a6c9b25ddf68e16cfa2ecc4](https://strategy-builder-front.pages.dev/strategy/0:dcdfdeaefca1c1d189a61317ce4b97f21fd6c7f73a6c9b25ddf68e16cfa2ecc4)

![Sample Strategy 3](docs/sample-strategy-3.png)

This Strategy add user WEVER to WEVER-USDT pool and lock lp in farm. **Owner of locked lp and reward is sender.**
Besides, this Strategy take 5% fee that sends to Strategy owner balance. 
It is a pipeline "receive token + swap in 50/50 proportion + provide liquidity to pool + receive LP + lock LP into farming pool + claim rewards method with optional recipient address" from challenge.

# Any to WEVER

MainNet address: ``

UI viewer link: [https://strategy-builder-front.pages.dev/strategy/0](https://strategy-builder-front.pages.dev/strategy/0)

[img]

This Strategy swaps any token from USDT/USDC/BRIDGE/QUBE/WBTC/WETH/DAI/PURR to WEVER and
sends them to sender. Very useful Strategy that can be user as a part of another Strategy (see next sample)

# Fill pool

MainNet address: ``

UI viewer link: [https://strategy-builder-front.pages.dev/strategy/0](https://strategy-builder-front.pages.dev/strategy/0)

[img]

This Strategy swaps USDT/USDC to WEVER, send them to pool WEVER-BRIDGE and lock lp in farm.
This is a sample how one Strategy can use another. The owner of lp and reward is Strategy. If owner
wants to claim reward, he can call `claim` method in Strategy (see [Additional Functions](#Additional-Functions)).
This Strategy can be used for autofill pool from, where incoming tokens is some commissions in some service
