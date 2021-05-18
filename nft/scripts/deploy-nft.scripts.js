const hre = require("hardhat")

const main = async () => {
  const HodooiFactory = await hre.ethers.getContractFactory("HodooiNFT")
  const hodooi = await HodooiFactory.deploy()
  await hodooi.deployed()

  console.log("Hodooi deployed at: ", hodooi.address)
}

main()