// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const [admin] = await hre.ethers.getSigners();
  // DEPLOY HODOOI EXCHANGE
  const bnbRouter = '0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F';
  // const usdt = '0x584119951fA66bf223312A29FB6EDEBdd957C5d8';
  const usdt = '0x55d398326f99059fF775485246999027B3197955';
  const busd = '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56';
  const bnb = '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c';

  const HodooiExchange = await hre.ethers.getContractFactory("HodooiExchange");
  const hodooiExchange = await HodooiExchange.deploy(bnbRouter, usdt, busd, bnb);

  await hodooiExchange.deployed();

  console.log("HodooiExchange deployed to:", hodooiExchange.address);

  // DEPLOY REFERRAL
  const HodooiReferral = await hre.ethers.getContractFactory("HodooiReferral");
  const hodooiReferral = await HodooiReferral.deploy(admin.address);

  await hodooiReferral.deployed();

  console.log("HodooiReferral deployed to:", hodooiReferral.address);

  // DEPLOY MARKET
  const HodooiMarket = await hre.ethers.getContractFactory("HodooiMarket");
  const hodooiMarket = await HodooiMarket.deploy();

  await hodooiMarket.deployed();

  console.log("HodooiMarket deployed to:", hodooiMarket.address);

  // CONFIGURE MARKET
  const marketFee = 250;
  const firstSellFee = 250;
  const artistLoyaltyFee = 5000;
  const referralFee = 5000;

  await hodooiMarket.setSotaExchangeContract(hodooiExchange.address);
  await hodooiMarket.setReferralContract(hodooiReferral.address);
  await hodooiMarket.setSystemFee(marketFee,  firstSellFee,  artistLoyaltyFee,  referralFee);
  await hodooiMarket.setWhiteListPayableToken(usdt, 1);

  // CONFIGURE REFERRAL
  await hodooiReferral.setMarket(hodooiMarket.address);

  await hre.run("verify:verify", {
    address: hodooiExchange.address,
    constructorArguments: [bnbRouter, usdt, busd, bnb],
  })
  await hre.run("verify:verify", {
    address: hodooiReferral.address,
    constructorArguments: [admin.address],
  })
  await hre.run("verify:verify", {
    address: hodooiMarket.address,
    constructorArguments: [],
  })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
