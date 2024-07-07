require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
// require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

const { IPSCHAIN_USERNAME, IPSCHAIN_PASSWORD, PRIVATE_KEY} = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    ipschain_dev: {
      url: `https://${IPSCHAIN_USERNAME}:${IPSCHAIN_PASSWORD}@ipschain.ipsprotocol.xyz`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    local: {
      url: `http://127.0.0.1:8545`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      timeout: 1800000 // 30 minutes, if applicable for your specific debugging tools or scripts

    },
  },
  etherscan:{
    apiKey:{
      ipschain_dev: "something"
    },
    customChains: [
      {
        network: "ipschain_dev",
        chainId: 8337,
        urls: {
          apiURL: "https://explorer.ipsprotocol.xyz/api",
          browserURL: "https://explorer.ipsprotocol.xyz"
        }
      }
    ]
  }
};

