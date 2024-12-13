require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-ethers");
// require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();


task("nft", "run the nft hack flow")
  .addParam("tokens", "The Number of tokens the Hacker will obtain.")
  .setAction(async (taskArgs, hre) => {
    const { tokens } = taskArgs; // Extract lowercase parameter
    const { main } = require("./scripts/nft-reentrancy/run_nft_reentrancy.js");
    await main(tokens, hre);
  });

  task("erc20", "run the ERC20")
  .addParam("tokens", "The Number of tokens the Hacker will obtain.")
  .setAction(async (taskArgs, hre) => {
    const { tokens } = taskArgs; // Extract lowercase parameter
    const { main } = require("./scripts/nft-reentrancy/run_nft_reentrancy.js");
    await main(tokens, hre);
  });


const { IPSCHAIN_USERNAME, IPSCHAIN_PASSWORD, PRIVATE_KEY} = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    ipschain_testnet: {
      url: `https://${IPSCHAIN_USERNAME}:${IPSCHAIN_PASSWORD}@ipschain.ipsprotocol.xyz`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    local: {
      url: `http://127.0.0.1:8545`,
      accounts: [`0x${PRIVATE_KEY}`],
      timeout: 1800000 // 30 minutes, if applicable for your specific debugging tools or scripts
    },
    node: {
      url: `http://127.0.0.1:8545`,
    }
  },
  etherscan:{
    apiKey:{
      ipschain_testnet: "something"
    },
    customChains: [
      {
        network: "ipschain_testnet",
        chainId: 8337,
        urls: {
          apiURL: "https://explorer.ipsprotocol.xyz/api",
          browserURL: "https://explorer.ipsprotocol.xyz"
        }
      }
    ]
  }
};

