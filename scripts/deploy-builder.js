const {
  logContract,
  logger
} = require('./utils');


const main = async () => {
  const [keyPair] = await locklift.keys.getKeyPairs();
  const Builder = await locklift.factory.getAccount('StrategyBuilder');
  const Platform = await locklift.factory.getContract('Platform');
  const Strategy = await locklift.factory.getContract('Strategy');

  logger.log('Deploying Strategy Builder');
  let builder = await locklift.giver.deployContract({
    contract: Builder,
    constructorParams: {
      owner: '0:fa94171cb0565789224814561cc558e59315971ee9d03085de3dcb5f8b94d95e',
      platformCode: Platform.code,
      strategyCode: Strategy.code,
    },
    initParams: {
      // _randomNonce: locklift.utils.getRandomNonce(),
      _randomNonce: 6900,
    },
    keyPair
  }, locklift.utils.convertCrystal(3, 'nano'));
  console.log(builder.address);
  await logContract(builder);
};


main()
  .then(() => process.exit(0))
  .catch(e => {
    console.log(e);
    process.exit(1);
  });
