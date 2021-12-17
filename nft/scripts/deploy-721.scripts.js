const hre = require("hardhat")

const main = async () => {
	const HodooiFactory = await hre.ethers.getContractFactory("Hod721General")
	  const hodooi = await HodooiFactory.deploy()
	  await hodooi.deployed()

	console.log("Hodooi deployed at: ", hodooi.address)

	  await hre.run("verify:verify", {
	    address: hodooi.address,
	    constructorArguments: [],
	    contract: "contracts/Hod721General.sol:Hod721General"
	  })
}

main()