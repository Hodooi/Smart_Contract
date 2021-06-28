/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-abi-exporter");
require("dotenv").config();

module.exports = {
  solidity: "0.5.16",
  networks: {
    testnet: {
      url: "https://data-seed-prebsc-2-s1.binance.org:8545",
      accounts: [process.env.PRIVATE_KEY],
    },
    bsc_mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      accounts: [process.env.PRIVATE_KEY],
    }
  },
  etherscan: {
    apiKey: process.env.BSC_API_KEY
  },
};
