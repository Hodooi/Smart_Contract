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
  // const bnbRouter = '0xD1E12E525dAe581CB3CCA551734d3BAFd2E8cE0C';
  // const usdt = '0x14ec6EE23dD1589ea147deB6c41d5Ae3d6544893';
  // const busd = '0x1a0B0c776950e31b05FB25e3d7E14f99592bFB71';
  // const bnb = '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd';
  const bnbRouter = '0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3';
  const usdt = '0x7ef95a0fee0dd31b22626fa2e10ee6a223f8a684';
  const busd = '0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7';
  const bnb = '0xae13d989dac2f0debff460ac112a837c89baa7cd';

  const HodooiExchange = await hre.ethers.getContractFactory("HodooiExchange");
  const hodooiExchange = await HodooiExchange.deploy(bnbRouter, usdt, busd, bnb);
  // const hodooiExchange = await HodooiExchange.attach("0x9EebF8f6cf7Cb7099fAb0cC25A9E314522c3f8E5");

  await hodooiExchange.deployed();

  console.log("HodooiExchange deployed to:", hodooiExchange.address);

  await hre.run("verify:verify", {
    address: hodooiExchange.address,
    constructorArguments: [bnbRouter, usdt, busd, bnb],
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