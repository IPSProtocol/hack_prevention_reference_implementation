const fs = require("fs");
const path = require("path");
const { task } = require("hardhat/config");
const { ethers } = require("ethers");
require("dotenv").config();

task("create-keystore", "Creates an Ethereum-compatible keystore file")
  .addParam("password", "The password to encrypt the keystore file")
  .setAction(async (taskArgs) => {
    const { password } = taskArgs;

    // Create the keystore directory if it doesn't exist
    const keystoreDir = process.env.KEYSTORE_PATH || "./keystore";
    if (!fs.existsSync(keystoreDir)) {
      fs.mkdirSync(keystoreDir, { recursive: true });
      console.log(`Created keystore directory: ${keystoreDir}`);
    }

    // Generate a new wallet
    const wallet = ethers.Wallet.createRandom();
    console.log("Generated new wallet:");
    console.log("Address:", wallet.address);

    // Encrypt the wallet to create the keystore
    console.log("Encrypting the wallet...");
    const keystore = await wallet.encrypt(password);

    // Define the output file path
    const outputPath = path.join(keystoreDir, `UTC--${new Date().toISOString()}--${wallet.address}.json`);

    // Save the keystore to the file
    fs.writeFileSync(outputPath, keystore);
    console.log(`Keystore saved to: ${outputPath}`);
  });
