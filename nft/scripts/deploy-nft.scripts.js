const hre = require("hardhat")

const main = async () => {
	const HodooiFactory = await hre.ethers.getContractFactory("HodooiNFT")
	//   const hodooi = await HodooiFactory.deploy()
	const hodooi = await HodooiFactory.attach("0x609BB0A259E209e57c98BE2A7c6A6fec0a4aF59c")
	//   await hodooi.deployed()

	console.log("Hodooi deployed at: ", hodooi.address)

	//   await hre.run("verify:verify", {
	//     address: hodooi.address,
	//     constructorArguments: [],
	//     contract: "contracts/HodooiNFT.sol:HodooiNFT"
	//   })
	await hodooi.create("1", "1", "2000", "", "0x")
}

main()