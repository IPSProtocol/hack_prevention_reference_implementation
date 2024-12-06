const { ethers } = require("hardhat");
require('dotenv').config();

const fs = require('fs');
const { getSigner } = require("@openzeppelin/hardhat-upgrades/dist/utils");


async function main() {

  let SafeNFT, NFTHack, safeNFT, nftHack;

  const nftPrice = 1

  const provider = ethers.provider
  // network name passed by command line
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

  // Deploy  TransactionEvents library 
  transactionEventsLib = await ethers.getContractFactory("TransactionEventsLib");
  transactionEventsLib = await transactionEventsLib.connect(wallet).deploy()
  await transactionEventsLib.waitForDeployment();

  console.log(`Deployed TransactionEventsLib address: ${transactionEventsLib.target}`);


  // Get the ContractFactory and Signers here.
  SafeNFT = await ethers.getContractFactory("SafeNFT");
  NFTHack = await ethers.getContractFactory("NFTHack");
  NFTFirewallContract = await ethers.getContractFactory("NFTFirewallContract", { libraries: { TransactionEventsLib: transactionEventsLib.target } });

  // Deploy sec contract
  nftFirewallContract = await NFTFirewallContract.connect(wallet).deploy()

  await nftFirewallContract.waitForDeployment()


  console.log(`Deployed nftFirewallContract address: ${nftFirewallContract.target}`);

  safeNFT = await SafeNFT.connect(wallet).deploy(nftFirewallContract.target, "Safe NFT", "SAFENFT", nftPrice);
  await safeNFT.waitForDeployment();

  console.log(`Deployed safeNFT address: ${safeNFT.target}`);
  value = await provider.getStorage(safeNFT.target, "0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f")
  // value = await safeNFT.connect(wallet).getAddressFromSlot()
  console.log(`Firewall contract set at 0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f has value: ${value}`);



  nftHack = await NFTHack.connect(wallet).deploy(safeNFT.target);
  await nftHack.waitForDeployment();


  console.log(`Deployed NFTHack address: ${nftHack.target}`);
  console.log("________________________")
  console.log("________________________")
  console.log("")

  try {
    console.log("3 - Attacker is buying 1 NFT")
    console.log("________________________\n")
    buyTx = await nftHack.connect(wallet).buy({ value: nftPrice });
    buyTx = await buyTx.wait()
    console.log("NFT Acquisition Tx Hash: " + buyTx.hash)
    console.log("________________________")
    console.log("")
  }
  catch (error) {
    tx_hash = error.receipt['hash']
    console.log("Claiming Tx Hash: " + tx_hash)
    const txTrace = await ethers.provider.send('debug_traceTransaction', [tx_hash]);
    const reasonHex = txTrace.returnValue;
    const reason = ethers.toUtf8String('0x' + reasonHex.substring(136));
    console.log()
    console.log('Revert reason:', reason);
    console.log("\n________________________")
  }
  try {

    console.log("4 - Attack vulnerable Claim function!");
    console.log("________________________\n")
    tx = await nftHack.connect(wallet).claim();
    tx_res = await tx.wait()
    console.log("Claiming Tx Hash: " + tx_res['hash'])
    console.log("Claiming NFT Passed: " + Boolean(tx_res['status']))
    hacker_balance = await safeNFT.balanceOf(nftHack.target)
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