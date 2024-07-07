# IPSChain Reference Implementation
This repository serves as a comprehensive archive of documented and scripts of historical smart contract exploits. The goal is to demonstrate how these exploits can be effectively prevented using the IPSChain decentralized firewall technology.

The primary goal of this repository is to educate developers, security researchers, and enthusiasts on the importance of robust contract implementations and how to protect them effectively using the innovative solution provided by IPSChain. 

If you want to know more about IPSProtocol, check thw follwing links:

- [Website](https://ipsprotocol.xyz)
- [User and Concepts Documentation](https://docs.ipsprotocol.xyz)
- [Explorer](https://explorer.ipsprotocol.xyz)


Let's make Web3 secure! Join: <br>
- [Discord](https://discord.gg/GT6BpJqy) 
- [Telegram](https://t.me/+hSp2Kr_exIc5ZDA0)

## Contents of the Repository
For each documented exploit, the repository includes the following components:

- Vulnerable Contracts: These are the decentralized application contracts that were compromised.
- Attacking Contract Implementation: This contains the implementation details of a contract designed to replicate the hack.
- **Firewall Contract**: A specialized contract on the IPSChain, executed at the end of the transaction, that is capable of identifying and preventing the documented hack. for more details about the Firewall Contracts and the Decentralized Firewall Technology. check out [here](https://docs.ipsprotocol.xyz)
- Deployment Script: We provide a Hardhat script that automates the deployment of the contracts and the execution of the hack on a insecure chain and on IPSChain.

## Getting Started

**Step 1** Install Node v18.18.2 or v20.12.2(LTS) - [Download site](https://nodejs.org/en/download)

**Step 2** Install Hardhat 2.22.3 - [Guide](https://hardhat.org/hardhat-runner/docs/getting-started#installation)


**Step 3** - Contact the IPSChain Team on [Discord](https://discord.gg/k4Q5JspK) or [Telegram](https://t.me/+hSp2Kr_exIc5ZDA0) to request:

1. IPSChain credentials for RPC Node connectivity.
2. IPS tokens by providing your wallet address.

### Hardhat Configuration

#### Configuration variables

1. Ensure that you create an .env file in the project root directory containing the following variables:
```bash
$ touch .env
```
2. Setup the variables:
```
IPSCHAIN_USERNAME=XXXXX
IPSCHAIN_PASSWORD=XXXXX
PRIVATE_KEY=XXXXX
```

3. Import the variables in the hardhat configuration file ```hardhat.config.js```:

- IPSCHAIN_USERNAME and IPSCHAIN_PASSWORD should be provided by the **IPSChain team**
- PRIVATE_KEY should be the private key of a wallet you'll be using for testing IPSChain. The **IPSChain team** will send you gas tokens.

The following two variables are used in the run_nft_reentrancy.js file:

- KEYSTORE_PATH: This variable specifies the path to the keystore that you have created locally for your private key.
- LOCAL_KEYSTORE_PASSWORD: This variable holds the password required to access the keystore and retrieve your private key.

![Hardhat Config](./images/hardhat_conf_env.png)

#### IPSChain Configuration

1. Add the IPSChain Configuration in hardhat config file: ```hardhat.config.js```:

![IPSChain configuration](./images/network_configuration.png)

### Running Scenarios

Running scenarios for now displays information on the terminal about the hack execution.

#### Locally with Hardhat Node

One can run the scenarios on hardhat 
```bash
$ npx hardhat run scripts/nft-reentrancy/run_nft_reentrancy.js --network hardhat
```

When running nft reentrancy hack on hardhat, one can see the hack went trough. and hacker was able to buy 1 NFT and collect 5.

```text
4 - Attack vulnerable Claim function!
________________________

Claiming Tx Hash: 0xac04660bc485da5cd5ff3eee9a9e0318dc15093652a663249fce97baa300ed93
Claiming NFT Passed: true
Number of Claimed NFTs : 5
________________________
```



#### IPSChain

One can run the scenarios on the IPSChain 
```bash
$ npx hardhat run scripts/nft-reentrancy/run_nft_reentrancy.js --network ipschain
```

When running nft reentrancy hack on hardhat, one can see the hack went trough. Transaction was reverted.

```text
4 - Attack vulnerable Claim function!
________________________

Claiming Tx Hash: 0x9b5a30ac3adc3ec641102bbbfcea87ff723a13d532a19498495cb3525794d80d
Claiming NFT Passed: False

Revert reason: ipschainsecurity: Reentrancy attack detected, reverting transaction
________________________
```


Please review the transaction that was reverted by searching for the transaction hash on our  [explorer](https://explorer.ipsprotocol.xyz).

**IMPORTANT NOTE: Not only was the hack reverted, but the malicious transaction was also recorded on the blockchain, complete with all its details. This provides valuable insights into potential vulnerabilities for decentralized applications. Monitoring projects can now concentrate on alerting about attempted hacks.**


### (Optional) Metamask setup

After obtaining your chain credentials, You could setup your metamask wallet to check the gas tokens and manage them accordingly. once you receive your credentials set the URL with your values:

```
https://USENAME:PASSWORD@ipschain.ipsprotocol.xyz
```

ChainId: 8337  

![IPSChain Metamask Setup](./images/wallet_conf.png)