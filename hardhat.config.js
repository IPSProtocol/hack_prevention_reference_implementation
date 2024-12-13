require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-ethers");
// require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();


task("hack-nft", "run the nft hack flow")
  .addParam("tokens", "The Number of tokens the Hacker will obtain.")
  .setAction(async (taskArgs, hre) => {
    const { tokens } = taskArgs; // Extract lowercase parameter
    // Validate tokens with meaningful feedback
    if (tokens <= 0 || tokens >= 61) {
      console.error("Error: The number of tokens must be between 1 and 60.");
      return; // Exit the task early if invalid
    }
    const { main } = require("./scripts/nft-reentrancy/run_nft_reentrancy.js");
    await main(tokens, hre);
  });

task("hack-erc20", "run the ERC20")
  .addParam("tokens", "The Number of tokens the Hacker will obtain.")
  .setAction(async (taskArgs, hre) => {
    const { tokens } = taskArgs; // Extract lowercase parameter
    const { main } = require("./scripts/nft-reentrancy/run_nft_reentrancy.js");
    await main(tokens, hre);
  });


const { DECENTRALIZED_FIREWALL_USERNAME, DECENTRALIZED_FIREWALL_PASSWORD, SEPOLIA_RPC_URL, PRIVATE_KEY } = process.env;

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

