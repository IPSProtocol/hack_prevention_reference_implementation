const { ethers } = require("hardhat");
require('dotenv').config();

const fs = require('fs');

const { deployContract, getWallet, DeployTransactionEventsLib, logWalletDetails, verifyFirewallContractSetup } = require("./scripts/utils.js");

async function deployFirewallContract(wallet, transactionEventsLib) {
  vulnERC20FirewallContract = await ethers.getContractFactory("VulnERC20FirewallContract", { libraries: { TransactionEventsLib: transactionEventsLib.target } });
  vulnERC20FirewallContract = await vulnERC20FirewallContract.connect(wallet).deploy()

  await vulnERC20FirewallContract.waitForDeployment()

  console.log(`Deployed vulnERC20FirewallContract address: ${vulnERC20FirewallContract.target}`);

  return vulnERC20FirewallContract;
}
async function deployMyVulnERC20Token(wallet, vulnERC20FirewallContract, supply) {
  return await deployContract(wallet, "MyVulnERC20", [supply, vulnERC20FirewallContract.target]);

}

async function main() {

  let myVulnERC20supply = 10000;

  const wallet = await getWallet(ethers.provider);

  await logWalletDetails(wallet, ethers.provider)

  let transactionEventsLib = await DeployTransactionEventsLib(wallet);
  let vulnERC20FirewallContract = await deployFirewallContract(wallet, transactionEventsLib);
  let businessLogicERC20 = await deployMyVulnERC20Token(wallet, vulnERC20FirewallContract, myVulnERC20supply);
  let hackVulnERC20 = await deployHackVulnERC20(wallet, businessLogicERC20);


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
    await getEmittedEvent(ethers.provider, pentestTx.hash)
  }
  catch (error) {
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

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });