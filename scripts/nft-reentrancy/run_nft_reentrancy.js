const { ethers } = require("hardhat");

const fs = require('fs');

async function main(){
      let SafeNFT, NFTHack, safeNFT, nftHack;
      const nftPrice = 1 ; 
        
        const provider =  ethers.provider

        const [wallet] =  await ethers.getSigners();
          
        console.log("1 - Wallet Details")
        console.log("########################")
        console.log(`Wallet address: ${wallet.address} - Balance: ${ await provider.getBalance(wallet.address) } `);
        console.log("########################")
        console.log("")
        console.log("2 - Contracts Details")
        console.log("########################")
        // Deploy  TransactionEvents library 
        transactionEventsLib = await ethers.getContractFactory("TransactionEventsLib");
        transactionEventsLib = await  transactionEventsLib.connect(wallet).deploy()
        await transactionEventsLib.waitForDeployment();
        
        console.log(`Deployed TransactionEventsLib address: ${transactionEventsLib.target}`);
        

        // Get the ContractFactory and Signers here.
        SafeNFT = await ethers.getContractFactory("SafeNFT");
        NFTHack = await ethers.getContractFactory("NFTHack");
        NFTFirewallContract = await ethers.getContractFactory("NFTFirewallContract",{libraries:{TransactionEventsLib:transactionEventsLib.target}});        

        // Deploy sec contract
        nftFirewallContract = await  NFTFirewallContract.connect(wallet).deploy()
        await nftFirewallContract.waitForDeployment()
        
        console.log(`Deployed nftFirewallContract address: ${nftFirewallContract.target}`);
        
        safeNFT = await SafeNFT.connect(wallet).deploy(nftFirewallContract.target,"ToBeHacked NFT", "TBH", nftPrice);
        await safeNFT.waitForDeployment();
        console.log(`Deployed safeNFT address: ${safeNFT.target}`);
        value = await provider.getStorage(safeNFT.target,"0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f")
        // value = await safeNFT.connect(wallet).getAddressFromSlot()
        console.log(`Firewall contract set at 0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f has value: ${value}`);

        
        
        nftHack = await NFTHack.connect(wallet).deploy(safeNFT.target);
        nftHack.waitForDeployment();
        console.log(`Deployed NFTHack address: ${nftHack.target}`);
        console.log("########################")
        console.log("")


        console.log("3 - Attacker is buying 1 NFT")
        console.log("########################")
        buyTx = await nftHack.connect(wallet).buy({ value: nftPrice});
        buyTx  = await buyTx.wait()
        console.log("NFT Acquisition Tx Hash: " + buyTx.hash)
        console.log("########################") 
        console.log("")
        try{

          console.log("4 - Attack vulnerable Claim function!");
          console.log("########################")
          tx = await nftHack.connect(wallet).claim();
          tx_res = await tx.wait()
          console.log("Claiming Tx Hash: " +tx_res['hash'])
          console.log("Claiming NFT Passed: " + Boolean(tx_res['status']))
          hacker_balance = await safeNFT.balanceOf(nftHack.target)
          console.log("Number of Claimed NFTs : " + hacker_balance)
          console.log("########################\n")
        }
        catch(error){
          
          tx_hash = error.receipt['hash']
          console.log("Claiming Tx Hash: " + tx_hash)
          console.log("Claiming NFT Passed: False")
          const txTrace = await ethers.provider.send('debug_traceTransaction', [tx_hash]);
          const reasonHex = txTrace.returnValue;
          
          
          const reason =  ethers.toUtf8String('0x' + reasonHex.substring(136));
          console.log()
          console.log('Revert reason:', reason);
          console.log("\n########################")

        }

        
    }


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });