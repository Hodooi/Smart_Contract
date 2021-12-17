const hre = require("hardhat");

async function main() {
  /**
   * Testnet
  */
  // const exchange = "0xbe3050809Aff0667836944233BAEAB7977aC39eD";
  // const referral = "0xa9fE22967de8B476725296cB2690C07c665cF787";
  // const usdt = "0x14ec6EE23dD1589ea147deB6c41d5Ae3d6544893";
  // const hod = "0xad956c3fff018726ed0ecd7531e45a71232f4fda"
  // const oldMarket = "0x2796F1901302E11205b7588fE77B0a24B9460Ad6";

  /**
   * Mainnet
  */
  const exchange = "0x2C20f6EEfd6B5941510224F8Ca5ad5a90Be8DFFf";
  const referral = "0x25B7bB20667F3d55EB1707D54862210A7A0165eb";
  const usdt = "0x55d398326f99059ff775485246999027b3197955";
  const hod = "0x19A4866a85c652EB4a2ED44c42e4CB2863a62D51"
  const oldMarket = "0x681177787efFF296710117782840cfA87662f34E";
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