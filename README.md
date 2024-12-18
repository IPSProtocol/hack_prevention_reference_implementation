# Decentralized Firewall 
## Enabling Reliable, Decentralized, Scalable, Deterministic and Unavoidable Hack Prevention for Smart Contracts 

## Overview

This repository showcases various historical **smart contract hack scenarios** and demonstrates how they can be **prevented** by leveraging our **Firewall Contract**, the core technology of our **Decentralized Firewall**. 

It serves as a reference implementation for documented historical smart contract exploits and includes scripts to reproduce these scenarios. The primary goal is to highlight how these exploits can be effectively prevented using **IPSProtocol's Decentralized Firewall Technology**, which is easily pluggable into any EVM-compatible blockchain.


## Purpose

The primary objective of this repository is to **educate and empower developers, security researchers, and blockchain enthusiasts** by introducing a new paradigm: the Firewall Layer, which leverages **dynamic security analysis** to enable **hack prevention** in a decentralized, transparent, and deterministic manner.


## Learn More

If you're interested in exploring the **Decentralized Firewall** and the **Firewall Layer Vision**, visit the following resources:

- [**IPSProtocol Website**](https://ipsprotocol.xyz)  
- [**User Documentation**](https://docs.ipsprotocol.xyz)  
- [**Decentralized Firewall Explorer**](https://explorer.ipsprotocol.xyz)  


Or join our community:  

- [**Discord**](https://discord.gg/vjAtSFdCt5)  
- [**Telegram**](https://t.me/+hSp2Kr_exIc5ZDA0)  

## Contents of the Repository

For each documented exploit, we provide code to demonstrate and reproduce the hack, along with the necessary technology to prevent such incidents from occurring in the future.  
This repository includes the following components:

- **Vulnerable Contracts**: Decentralized application contracts that were exploited in the documented scenarios.  
- **Attacking Contract Implementation**: Detailed implementations of contracts designed to replicate the exploits.  
- **Firewall Contract**: A specialized contract managed by the Decentralized Firewall, executed at the end of the transaction to identify and prevent the documented hack. For more information about Firewall Contracts and the Decentralized Firewall Technology, visit [this link](https://docs.ipsprotocol.xyz).  
- **Hack Simulation Script**: A Hardhat task that automates the deployment of smart contracts and execution of the hack on both Ethereum testnets and the Decentralized Firewall Testnet.


## Getting Started 

### Installation

**Step 1** Install Node v18.18.2 or v20.12.2 (LTS) - [Download site](https://nodejs.org/en/download)

**Step 2** Install the project's dependencies:
```bash
npm install
```

**Step 3** Contact the Decentralized Firewall Team on [Discord](https://discord.gg/k4Q5JspK) or [Telegram](https://t.me/+hSp2Kr_exIc5ZDA0) to request:
1. Decentralized Firewall credentials for RPC Node connectivity.
2. Gas tokens by providing your wallet address.

## Hardhat Configuration

#### Environment Variables configuration

1. Ensure that you create an `.env` file in the project root directory containing the following variables:
```bash
 touch .env
```
2. Configure the `.env` file:
```
DECENTRALIZE_FIREWALL_USERNAME=XXXXX
DECENTRALIZE_FIREWALL_PASSWORD=XXXXX
PRIVATE_KEY=XXXXX
KEYSTORE_PATH=XXXXX 
KEYSTORE_PASSWORD=XXXXX
```

3. Import the variables in the Hardhat configuration file `hardhat.config.js`:
- `DECENTRALIZE_FIREWALL_USERNAME` and `DECENTRALIZE_FIREWALL_PASSWORD` should be provided by the **Decentralized Firewall Team**.

For wallet keys, we recommend a more secure approach by using a keystore instead of directly exposing your private key, even if the wallet does not contain any funds.  

- **`KEYSTORE_PATH`**: Specifies the path to the keystore you have created locally to store your private key securely.  
- **`KEYSTORE_PASSWORD`**: Holds the password required to access the keystore and retrieve your private key.  

If you choose to accept the risk, you can set the private key directly using the following variable:  

- **`PRIVATE_KEY`**: The private key of a wallet you will use for testing the Decentralized Firewall Network. The **Decentralized Firewall Team** will provide you with gas tokens for testing purposes.


To import the variables, just set as follows:

```javascript

require('dotenv').config();

const { DECENTRALIZED_FIREWALL_USERNAME, DECENTRALIZED_FIREWALL_PASSWORD, SEPOLIA_RPC_URL, PRIVATE_KEY } = process.env;

```

### Decentralized Firewall Configuration

1. Add the Decentralized Firewall Configuration in the Hardhat config file: `hardhat.config.js`:

```javascript
module.exports = {
  solidity: "0.8.24",
  networks: {
    decentralized_firewall_testnet: {
      url: `https://${DECENTRALIZED_FIREWALL_USERNAME}:${DECENTRALIZED_FIREWALL_PASSWORD}@ipschain.ipsprotocol.xyz`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    local: {
      url: `http://127.0.0.1:8545`,
      accounts: [`0x${PRIVATE_KEY}`],
      timeout: 1800000 // 30 minutes, if applicable for your specific debugging tools or scripts
    },
    sepolia: {
      url: `${SEPOLIA_RPC_URL}`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    node: {
      url: `http://127.0.0.1:8545`,
    }
  },
  etherscan: {
    apiKey: {
      decentralized_firewall_testnet: "let_him_cook"
    },
    customChains: [
      {
        network: "decentralized_firewall_testnet",
        chainId: 8337,
        urls: {
          apiURL: "https://explorer.ipsprotocol.xyz/api",
          browserURL: "https://explorer.ipsprotocol.xyz"
        }
      }
    ]
  }
```
## Hack Prevention Demos

Running historical hacks and their prevention mechanisms. Currently, this process will display information on the terminal about the hack execution.

### Locally with Hardhat Node

1. Open a terminal and start a Hardhat node:
```bash
$ npx hardhat node
```
2. To run the NFT Reentrancy Reference implementation scenario on Hardhat:
```bash
$ npx hardhat hack-nft --network node --tokens 5
```

When running an NFT reentrancy hack on Hardhat, you will observe that the hack succeeds and the hacker is able to buy 1 NFT and is able to claim 5 Tokens.

```bash
4 - Attack vulnerable Claim function!
________________________

Claiming Tx Hash: 0xac04660bc485da5cd5ff3eee9a9e0318dc15093652a663249fce97baa300ed93
Claiming NFT Passed: true
Number of Claimed NFTs : 5
________________________
```

### Decentralized Firewall Network

Run the scenarios on our Decentralized Firewall Network:
```bash
$ npx hardhat nft-hack --network decentralized_firewall_testnet --tokens 5
```

When running an NFT reentrancy hack on the Decentralized Firewall Testnet, you will observe that the hack is prevented:

```bash
3 - Attacker buys 1 NFT
________________________

NFT Acquisition Tx Hash: 0xc68592bf60a1ae0ee9ed2dedad90a602bda01734ebd0e212279a99a87f54cc86
________________________

4 - Attacks vulnerable Claim Function
________________________

Claiming Tx Hash: 0x09fab0bb99c42a6be8b8fad8918d0157e6463c2669e6fbc687d1872cfdc174d6
Claiming NFT Passed: False

Revert reason: DecentralizedFirewall: Invariant: Should Buy Before Claiming

________________________
```

While running on our Decentralized Firewall Network, the hack is effectively prevented.

One can review the transaction that was reverted by searching for the transaction hash on our [explorer](https://explorer.ipsprotocol.xyz).

**IMPORTANT NOTE**: Not only was the hack reverted, but the malicious transaction was also recorded on the blockchain, complete with all its details about the user that attempted to exploit the system, the contract logic, execution, and emitted events. This provides valuable insights into potential vulnerabilities for decentralized applications. Monitoring projects can now focus on alerting about attempted hacks. Thanks to our hack prevention capabilities, they will be able to take their time to identify the vectors of attack used, assess the risks, and evaluate whether to provide a fix or update the firewall contracts and invariants logic for long-term security against new attack vectors.

## (Optional) Metamask setup

After obtaining your chain credentials, you can set up your Metamask wallet to check the gas tokens and manage them accordingly. Once you receive your credentials, set the URL with your values:

```
https://USERNAME:PASSWORD@ipschain.ipsprotocol.xyz
```

ChainId: 8337  

![Decentralized Firewall Metamask Setup](./images/wallet_conf.png)
