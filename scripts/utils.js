const logger = require('mocha-logger');
const BigNumber = require('bignumber.js');
const chai = require('chai');
chai.use(require('chai-bignumber')());

const {expect} = chai;

const stringToHex = (s) => {
  return Buffer.from(s).toString('hex')
}

const logContract = async (contract) => {
  const balance = await locklift.ton.getBalance(contract.address);
  logger.log(`${contract.name} (${contract.address}) - ${locklift.utils.convertCrystal(balance, 'ton')}`);
};

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Due to the network lag, graphql may not catch wallets updates instantly
const afterRun = async (tx) => {
  if (locklift.network === 'dev' || locklift.network === 'prod') {
    await sleep(100000);
  }
  if (locklift.network === 'local') {
    await sleep(1000);
  }
};

module.exports = {
  logContract,
  afterRun,
  stringToHex,
  logger,
  expect,
};
