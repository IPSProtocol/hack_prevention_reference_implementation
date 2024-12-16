const { ethers,network } = require("hardhat");

const fs = require('fs');

async function main(){
      let SafeNFT, NFTHack, safeNFT, nftHack;
      const nftPrice = 1 ; 
        

          // Manually create a signer using the private key
      const provider = new ethers.JsonRpcProvider(network.config.url)
      const privateKey = process.env.PRIVATE_KEY;
      const wallet = new ethers.Wallet(privateKey, provider);
          
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
        await new Promise(f => setTimeout(f, 6000));
        try {
          await hre.run("verify:verify", {
            address: transactionEventsLib.target,
            constructorArguments: [], // Add actual constructor arguments if your contract has any
          });
        } catch (error) {
            console.error("TransactionEventsLib Verification failed:", error);
        }
        

        // Get the ContractFactory and Signers here.
        SafeNFT = await ethers.getContractFactory("SafeNFT");
        NFTHack = await ethers.getContractFactory("NFTHack");
        NFTFirewallContract = await ethers.getContractFactory("NFTFirewallContract",{libraries:{TransactionEventsLib:transactionEventsLib.target}});        

        // Deploy sec contract
        nftFirewallContract = await  NFTFirewallContract.connect(wallet).deploy()

        await nftFirewallContract.waitForDeployment()
        
        
        await new Promise(f => setTimeout(f, 6000));
        // Verify the contract after deployment
        try {
          await hre.run("verify:verify", {
            address: nftFirewallContract.target,
            constructorArguments: [], // Add actual constructor arguments if your contract has any
            libraries: {
              TransactionEventsLib: transactionEventsLib.target,
            },
            network: "ipschain_dev",
          });
        } catch (error) {
          if (!error.message.includes("VerificationAPIUnexpectedMessageError")) {
            console.error("NFTFirewallContract Verification failed:", error);
          }
        }
        
        console.log(`Deployed nftFirewallContract address: ${nftFirewallContract.target}`);
        
        safeNFT = await SafeNFT.connect(wallet).deploy(nftFirewallContract.target,"ToBeHacked NFT", "TBH", nftPrice);
        await safeNFT.waitForDeployment();

        // Verify the contract after deployment
        try {
          await hre.run("verify:verify", {
            address: safeNFT.target,
            constructorArguments: [nftFirewallContract.target,"ToBeHacked NFT", "TBH", nftPrice], // Add actual constructor arguments if your contract has any
            network: "ipschain_dev"
          });
        } catch (error) {
          console.error("SafeNFT Verification failed:", error);
        }
        
        console.log(`Deployed safeNFT address: ${safeNFT.target}`);
        value = await provider.getStorage(safeNFT.target,"0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f")
        // value = await safeNFT.connect(wallet).getAddressFromSlot()
        console.log(`Firewall contract set at 0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f has value: ${value}`);

        
        
        nftHack = await NFTHack.connect(wallet).deploy(safeNFT.target);
        nftHack.waitForDeployment();

        try {
          await hre.run("verify:verify", {
            address: nftHack.target,
            constructorArguments: [safeNFT.target], // Add actual constructor arguments if your contract has any
            network: "ipschain_dev"
          });
        } catch (error) {
          console.error("NFTHack Verification failed:", error);
        }
        try{
          const Faucet = await ethers.getContractFactory("Faucet");
          const faucet = await Faucet.deploy(ethers.utils.parseEther("0.05"), 24 * 60 * 60); // 0.01 ETH and 1 day lock time
          await faucet.deployed();
        
          console.log("Faucet deployed to:", faucet.address);

            // Verify the contract after deployment
        try {
          await hre.run("verify:verify", {
            address: faucet.target,
            constructorArguments: [ethers.utils.parseEther("0.05"), 24 * 60 * 60], // Add actual constructor arguments if your contract has any
            network: "ipschain_dev"
          });
        } catch (error) {
          console.error("SafeNFT Verification failed:", error);
        }
        }catch(error){
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