require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require('dotenv').config();

const { IPSCHAIN_USERNAME, IPSCHAIN_PASSWORD, PRIVATE_KEY} = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    ipschain: {
      url: `https://${IPSCHAIN_USERNAME}:${IPSCHAIN_PASSWORD}@ipschain.ipsprotocol.xyz`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
}};

