const { ethers } = require("hardhat");
require('dotenv').config();
require("@nomicfoundation/hardhat-ethers");


const { deployFirewall, deployContract, getWallet, logNewLines, DeployTransactionEventsLib } = require("../utils.js");



async function deployNFTFirewall(wallet, transactionEventsLib) {
  return await deployFirewall(wallet, "NFTFirewallContract", transactionEventsLib);
}

async function deployVulnNFT(wallet, nftFirewallContract, nftPrice) {
  return await deployContract(wallet, "VulnNFT", [nftFirewallContract.target, "Vuln NFT", "VNFT", nftPrice]);
}

async function deployNFTReentrancyHack(wallet, vulnNFT) {

  return await deployContract(wallet, "NFTReentrancyHack", [vulnNFT.target])
}




async function buyNFT(wallet, nftReentrancyHack, nftPrice) {
  try {
    console.log("3 - Attacker buys 1 NFT")
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
async function claim(wallet,vulnNFT, nftReentrancyHack, nbTokens) {
  try {

    console.log("4 - Attacks vulnerable Claim Function");
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

  let wallet = await getWallet(hre)

  // Deploy Contracts
  let transactionEventsLib = await DeployTransactionEventsLib(wallet)
  let nftFirewallContract = await deployNFTFirewall(wallet, transactionEventsLib)
  let vulnNFT = await deployVulnNFT(wallet, nftFirewallContract, nftPrice)
  let nftReentrancyHack = await deployNFTReentrancyHack(wallet, vulnNFT)

  logNewLines()

  await buyNFT(wallet, nftReentrancyHack, nftPrice)

  await claim(wallet,vulnNFT, nftReentrancyHack, nbTokens)

}




module.exports = { main }; // Ensure the function is exported
