const hre = require("hardhat")

const main = async () => {
	const HodooiFactory = await hre.ethers.getContractFactory("Hod721Artist")
	  const hodooi = await HodooiFactory.deploy('Hodooi flatform 721', 'HOD721A')
	  await hodooi.deployed('Hodooi flatform 721', 'HOD721A')

	console.log("Hodooi deployed at: ", hodooi.address)

	  await hre.run("verify:verify", {
	    address: hodooi.address,
	    constructorArguments: ['Hodooi flatform 721', 'HOD721A'],
	    contract: "contracts/Hod721Artist.sol:Hod721Artist"
	  })
}

main()