require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-ethers");
// require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();
// require("./tasks/create-keystore");
require("./tasks/hack-nft");
require("./tasks/hack-erc20");
const fs = require("fs");


const { DECENTRALIZED_FIREWALL_USERNAME, DECENTRALIZED_FIREWALL_PASSWORD, SEPOLIA_RPC_URL, PRIVATE_KEY } = process.env;
if (!fs.existsSync("./.env")) {
  throw new Error(".env file is missing.");
}

// Check if PRIVATE_KEY is set and valid
if (!process.env.SEPOLIA_RPC_URL) {
  throw new Error("SEPOLIA_RPC_URL Sepolia RPC URL variable not set. Either set it or remove the sepolia network configuration.");
}

// Check if PRIVATE_KEY is set and valid
if (!process.env.PRIVATE_KEY) {
  throw new Error("PRIVATE_KEY environment variable not set. either set it or remove it from in the networks configuration.");
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    decentralized_firewall_testnet: {
      url: `https://${DECENTRALIZED_FIREWALL_USERNAME}:${DECENTRALIZED_FIREWALL_PASSWORD}@ipschain.ipsprotocol.xyz`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    local: {
      url: `http://127.0.0.1:8545`,
      accounts: [`0x${PRIVATE_KEY}`],
      timeout: 1800000 // 30 minutes, if applicable for your specific debugging tools or scripts
    },
    sepolia: {
      url: `${SEPOLIA_RPC_URL}`,
      accounts: [`0x${PRIVATE_KEY}`],
      timeout: 1800000 // 30 minutes, if applicable for your specific debugging tools or scripts
    },
    node: {
      url: `http://127.0.0.1:8545`,
    }
  },
  etherscan: {
    apiKey: {
      decentralized_firewall_testnet: "let_him_cook"
    },
    customChains: [
      {
        network: "decentralized_firewall_testnet",
        chainId: 8337,
        urls: {
          apiURL: "https://explorer.ipsprotocol.xyz/api",
          browserURL: "https://explorer.ipsprotocol.xyz"
        }
      }
    ]
  }
};

