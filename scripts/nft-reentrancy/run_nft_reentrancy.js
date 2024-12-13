const { ethers } = require("hardhat");
require('dotenv').config();
require("@nomicfoundation/hardhat-ethers");
const fs = require('fs');


async function getWallet(hre) {

  const provider = ethers.provider

  const networkName = hre.network.name;
  let wallet;
  if (networkName == "hardhat") {
    [wallet] = await ethers.getSigners()

  }
  else {
    wallet = await getAccounts(provider)
  }

  console.log("1 - Wallet Details")
  console.log("________________________\n")
  console.log(`Wallet address: ${await wallet.address} - Balance: ${await provider.getBalance(wallet.address)} `);
  console.log("________________________")
  console.log("")
  console.log("2 - Contracts Details")
  console.log("________________________\n")

  return wallet
}



async function DeployTransactionEventsLib(wallet) {
  // Deploy  TransactionEvents library 
  transactionEventsLib = await ethers.getContractFactory("TransactionEventsLib");
  transactionEventsLib = await transactionEventsLib.connect(wallet).deploy()
  await transactionEventsLib.waitForDeployment();

  console.log(`Deployed TransactionEventsLib address: ${transactionEventsLib.target}`);
  return transactionEventsLib

}
async function deployNFTFirewall(wallet, transactionEventsLib) {
  let NFTFirewallContract = await ethers.getContractFactory("NFTFirewallContract", { libraries: { TransactionEventsLib: transactionEventsLib.target } });
  nftFirewallContract = await NFTFirewallContract.connect(wallet).deploy()
  await nftFirewallContract.waitForDeployment()

  console.log(`Deployed NFTFirewallContract address: ${nftFirewallContract.target}`);
  return nftFirewallContract;
}

async function deployVulnNFT(wallet, nftFirewallContract, nftPrice) {
  let VulnNFT = await ethers.getContractFactory("VulnNFT");
  vulnNFT = await VulnNFT.connect(wallet).deploy(nftFirewallContract.target, "Vuln NFT", "VNFT", nftPrice);
  await vulnNFT.waitForDeployment();

  console.log(`Deployed VulnNFT address: ${vulnNFT.target}`);
  return vulnNFT
}


async function deployNFTReentrancyHack(wallet, vulnNFT) {
  let NFTReentrancyHack = await ethers.getContractFactory("NFTReentrancyHack");
  nftReentrancyHack = await NFTReentrancyHack.connect(wallet).deploy(vulnNFT.target);
  await nftReentrancyHack.waitForDeployment();

  console.log(`Deployed NFTReentrancyHack address: ${nftReentrancyHack.target}`);
  return nftReentrancyHack
}


function logNewLines() {
  console.log("________________________")
  console.log("________________________")
  console.log("")
}


async function buyNFT(wallet, nftReentrancyHack, nftPrice) {
  try {
    console.log("3 - Attacker is buying 1 NFT")
    console.log("________________________\n")

    buyTx = await nftReentrancyHack.connect(wallet).buy({ value: nftPrice });
    buyTx = await buyTx.wait()

    console.log("NFT Acquisition Tx Hash: " + buyTx.hash)
    console.log("________________________")
    console.log("")
    return buyTx
  }
  catch (error) {
    console.log(error)
    tx_hash = error.receipt['hash']
    console.log("Claiming Tx Hash: " + tx_hash)
    const txTrace = await ethers.provider.send('debug_traceTransaction', [tx_hash]);
    const reasonHex = txTrace.returnValue;
    const reason = ethers.toUtf8String('0x' + reasonHex.substring(136));
    console.log()
    console.log('Revert reason:', reason);
    console.log("\n________________________")
  }
}
async function claim(wallet, nftReentrancyHack, nbTokens) {
  try {

    console.log("4 - Attack vulnerable Claim function!");
    console.log("________________________\n")

    tx = await nftReentrancyHack.connect(wallet).claim(nbTokens);
    tx_res = await tx.wait()

    console.log("Claiming Tx Hash: " + tx_res['hash'])
    console.log("Claiming NFT Passed: " + Boolean(tx_res['status']))

    hacker_balance = await vulnNFT.balanceOf(nftReentrancyHack.target)

    console.log("Number of Claimed NFTs : " + hacker_balance)
    console.log("________________________\n")

  }
  catch (error) {
    tx_hash = error.receipt['hash']
    console.log("Claiming Tx Hash: " + tx_hash)
    console.log("Claiming NFT Passed: False")

    const txTrace = await ethers.provider.send('debug_traceTransaction', [tx_hash]);
    const reasonHex = txTrace.returnValue;
    const reason = ethers.toUtf8String('0x' + reasonHex.substring(136));

    console.log()
    console.log('Revert reason:', reason);
    console.log("\n________________________")
  }
}
async function main(nbTokens, hre) {


  const nftPrice = 2

  let wallet = await  getWallet(hre)

  // Deploy Contracts
  let transactionEventsLib = await DeployTransactionEventsLib(wallet)
  let nftFirewallContract = await deployNFTFirewall(wallet,transactionEventsLib)
  let vulnNFT = await deployVulnNFT(wallet, nftFirewallContract, nftPrice)
  let nftReentrancyHack = await deployNFTReentrancyHack(wallet, vulnNFT)

  logNewLines()

  await buyNFT(wallet, nftReentrancyHack, nftPrice)

  await claim(wallet, nftReentrancyHack, nbTokens)

}

async function getAccounts(provider) {

  projectWallet = await loadWalletFromKeystore(process.env.KEYSTORE_PATH)
  projectWallet = await projectWallet.connect(provider)

  return projectWallet


}
async function loadWalletFromKeystore(path) {
  // Read the keystore file
  const keystore = fs.readFileSync(path, 'utf8');

  // Decrypt the keystore with the passworfd
  const password = process.env.LOCAL_KEYSTORE_PASSWORD; // Make sure to keep this secure
  const wallet = await ethers.Wallet.fromEncryptedJson(keystore, password);
  return wallet
}


module.exports = { main }; // Ensure the function is exported
