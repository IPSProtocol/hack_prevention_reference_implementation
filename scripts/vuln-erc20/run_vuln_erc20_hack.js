const { ethers } = require("hardhat");
require('dotenv').config();


const { deployContract, getWallet, logNewLines, DeployTransactionEventsLib } = require("../utils.js");

async function deployFirewallContract(wallet, transactionEventsLib) {
  VulnERC20FirewallContract = await ethers.getContractFactory("VulnERC20FirewallContract", { libraries: { TransactionEventsLib: transactionEventsLib.target } });
  vulnERC20FirewallContract = await VulnERC20FirewallContract.connect(wallet).deploy()

  await vulnERC20FirewallContract.waitForDeployment()

  console.log(`Deployed vulnERC20FirewallContract address: ${vulnERC20FirewallContract.target}`);

  return vulnERC20FirewallContract;
}
async function deployMyVulnERC20Token(wallet, vulnERC20FirewallContract, supply) {
  return await deployContract(wallet, "MyVulnERC20", [supply, vulnERC20FirewallContract.target]);
}

async function deployHackVulnERC20(wallet, vulnERC20) {
  return await deployContract(wallet, "HackVulnERC20", [vulnERC20.target]);
}

async function main(hre) {

  let myVulnERC20supply = 10000;

  const wallet = await getWallet(hre);


  let transactionEventsLib = await DeployTransactionEventsLib(wallet);
  let vulnERC20FirewallContract = await deployFirewallContract(wallet, transactionEventsLib);
  let myVulnERC20Token = await deployMyVulnERC20Token(wallet, vulnERC20FirewallContract, myVulnERC20supply);
  let hackVulnERC20 = await deployHackVulnERC20(wallet, myVulnERC20Token);


  // security checks Removed
  //  transferFrom from:0  =>  anyone can mint ERC20InvalidReceiver
  //  transferFrom to:0 => ERC20InvalidSender not checked
  //  transfer to:0 => ERC20InvalidSender not checked
  //  transferFrom allowance not checked. => ERC20InsufficientAllowance not check
  //  transferbalance not checked => ERC20InsufficientBalance not checkd
  //  burrn fom zero => ERC20InvalidSender not checkd
  try {

    pentestTx = await hackVulnERC20.connect(wallet).callAll()
    console.log(pentestTx.hash);
    let res = await (pentestTx).wait();
    console.log(res);
  }
  catch (error) {
    console.log(error)
    tx_hash = error.receipt['hash']
    console.log("Tx Hash: " + tx_hash)
    console.log("failed")
    const txTrace = await ethers.provider.send('debug_traceTransaction', [tx_hash]);
    const reasonHex = txTrace.returnValue;
    const reason = ethers.toUtf8String('0x' + reasonHex.substring(136));
    console.log()
    console.log('Revert reason:', reason);
    console.log("\n________________________")
    await getEmittedEvent(ethers.provider, tx_hash)
  }
}




module.exports = { main }; // Ensure the function is exported
