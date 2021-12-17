const hre = require("hardhat");

async function main() {
  // const exchange = "0x88e4C6808669ae32e8E0E242230F7212DfaBAE60";
  // const referral = "0x89EBf09B55CD85119C48254eE04B522d6e7fd72d";
  // const usdt = "0x14ec6EE23dD1589ea147deB6c41d5Ae3d6544893";
  const exchange = "0xbe3050809Aff0667836944233BAEAB7977aC39eD";
  const referral = "0xa9fE22967de8B476725296cB2690C07c665cF787";
  const usdt = "0x14ec6EE23dD1589ea147deB6c41d5Ae3d6544893";
  const hod = "0xad956c3fff018726ed0ecd7531e45a71232f4fda"
  const oldMarket = "0x2796F1901302E11205b7588fE77B0a24B9460Ad6";
  const limitAuction = 1;
  /// DEPLOY MARKET
  const HodooiMarket = await hre.ethers.getContractFactory("HodooiMarket");
  const hodooiMarket = await HodooiMarket.deploy(oldMarket, limitAuction);

  await hodooiMarket.deployed();

  console.log("HodooiMarket deployed to:", hodooiMarket.address);

  // CONFIGURE MARKET
  const marketFee = 250;
  const firstSellFee = 250;
  const artistLoyaltyFee = 5000;
  const referralFee = 5000;

  await hodooiMarket.setExchangeContract(exchange);
  await hodooiMarket.setReferralContract(referral);
  await hodooiMarket.setSystemFee(marketFee,  firstSellFee,  artistLoyaltyFee,  referralFee);
  await hodooiMarket.setWhiteListPayableToken(usdt, 1);
  await hodooiMarket.setWhiteListPayableToken(hod, 1);

  await hre.run("verify:verify", {
    address: hodooiMarket.address,
    constructorArguments: [oldMarket, limitAuction],
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