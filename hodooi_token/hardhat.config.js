// hardhat.config.js
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");

const ROPSTEN_PRIVATE_KEY = process.env.ROPSTEN_PRIVATE_KEY || "0000000000000000000000000000000000000000";
const ROPSTEN_INFURA_KEY = process.env.ROPSTEN_INFURA_KEY || '';

const MAINNET_PRIVATE_KEY = process.env.ROPSTEN_PRIVATE_KEY || "0000000000000000000000000000000000000000";
const MAINNET_INFURA_KEY = process.env.ROPSTEN_INFURA_KEY || '';


/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    solidity: "0.7.3",
    networks: {
        ropsten: {
            url: `https://ropsten.infura.io/v3/${ROPSTEN_INFURA_KEY}`,
            accounts: [`0x${ROPSTEN_PRIVATE_KEY}`]
        }
    }
};
