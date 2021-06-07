const hre = require("hardhat");

async function main() {
  const market = "";
  const admin = "0x94Ced899F5D635D364029AfDB88c41b16d47447e";
  // DEPLOY REFERRAL
  const HodooiReferral = await hre.ethers.getContractFactory("HodooiReferral");
  const hodooiReferral = await HodooiReferral.deploy(admin);

  await hodooiReferral.deployed();

  console.log("HodooiReferral deployed to:", hodooiReferral.address);

  // CONFIGURE REFERRAL
//   await hodooiReferral.setMarket(market);

  await hre.run("verify:verify", {
    address: hodooiReferral.address,
    constructorArguments: [admin],
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