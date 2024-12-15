
const fs = require('fs');

async function getWallet(hre) {
    const keystoreMode = checkEnvironmentVariables();
    const provider = ethers.provider
    const networkName = hre.network.name;
    let wallet;
    if (networkName == "hardhat" || networkName == "node") {
        [wallet] = await ethers.getSigners()
    }
    else {
        wallet = await getAccounts(provider, keystoreMode)
    }

    return wallet
}
function checkEnvironmentVariables() {
    keystoreMode = false;
    const {
        KEYSTORE_PATH,
        KEYSTORE_PASSWORD,
        PRIVATE_KEY,
        DECENTRALIZED_FIREWALL_USERNAME,
        DECENTRALIZED_FIREWALL_PASSWORD,
        SEPOLIA_RPC_URL,
    } = process.env;

    if (KEYSTORE_PATH && KEYSTORE_PASSWORD) {
        console.log("Keystore is properly configured.");
        keystoreMode = true;
    } else {
        console.log(
            "Keystore configuration is incomplete. both KEYSTORE_PATH and KEYSTORE_PASSWORD are required."
        );

        if (PRIVATE_KEY) {
            console.log("Private key is set and will be used instead.");
            keystoreMode = false;
        } else {
            console.error(
                "Neither keystore configuration nor private key is set. Please configure the environment variables properly for using Decentralized Firewall Network."
            );
        }
    }

    // Additional logging for other required variables
    if (!DECENTRALIZED_FIREWALL_USERNAME || !DECENTRALIZED_FIREWALL_PASSWORD) {
        console.error(
            "Missing credentials for the Decentralized Firewall. Ensure DECENTRALIZED_FIREWALL_USERNAME and DECENTRALIZED_FIREWALL_PASSWORD are set."
        );
    }

    if (!SEPOLIA_RPC_URL) {
        console.error("Missing SEPOLIA_RPC_URL. Ensure it is set in the environment.");
    }
    return keystoreMode;
}



async function logWalletDetails(wallet, provider) {
    console.log("1 - Wallet Details")
    console.log("________________________\n")
    console.log(`Wallet address: ${await wallet.address} - Balance: ${await provider.getBalance(wallet.address)} `);
    console.log("________________________")
    console.log("")
    console.log("2 - Contracts Details")
    console.log("________________________\n")

}

async function getAccounts(provider, keystoreMode) {
    let projectWallet;
    if (keystoreMode) {
        projectWallet = await loadWalletFromKeystore(process.env.KEYSTORE_PATH)
        projectWallet = await projectWallet.connect(provider)
    }
    else {
        projectWallet = new ethers.Wallet(process.env.PRIVATE_KEY,provider);
    }
    return projectWallet


}
async function loadWalletFromKeystore(path) {
    // Read the keystore file
    const keystore = fs.readFileSync(path, 'utf8');

    // Decrypt the keystore with the passworfd
    const password = process.env.KEYSTORE_PASSWORD; // Make sure to keep this secure
    const wallet = await ethers.Wallet.fromEncryptedJson(keystore, password);
    return wallet
}
function logNewLines() {
    console.log("________________________")
    console.log("________________________")
    console.log("")
}
async function DeployTransactionEventsLib(wallet) {
    // Deploy  TransactionEvents library 
    transactionEventsLib = await ethers.getContractFactory("TransactionEventsLib");
    transactionEventsLib = await transactionEventsLib.connect(wallet).deploy()
    await transactionEventsLib.waitForDeployment();

    console.log(`Deployed TransactionEventsLib address: ${transactionEventsLib.target}`);
    return transactionEventsLib

}
async function verifyFirewallContractSetup(provider, businesLogicERC20, vulnERC20FirewallContract) {
    let value = await provider.getStorage(businesLogicERC20.target, "0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f")
    value = value.slice(-40).toLowerCase();
    let addr = vulnERC20FirewallContract.target.slice(-40).toLowerCase();
    console.log(`is Firewall Contract Properly Setup: ${addr == value}`);
    console.log(`Firewall contract set at 0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f has value: ${value}`);
}
async function getEmittedEvent(provider, txHash) {
    // Fetch the transaction receipt
    const receipt = await provider.getTransactionReceipt(txHash);
    console.log(receipt)

    // Log all events in the receipt
    for (const log of receipt.logs) {
        try {
            // Define the ABI for the NEWADDR event
            const iface = new ethers.utils.Interface([
                "event NEWADDR(address)"
            ]);

            // Decode the log using the ABI
            const decodedLog = iface.parseLog(log);

            if (decodedLog.name === "NEWADDR") {
                console.log("NEWADDR Event Found!");
                console.log(`Caller Address: ${decodedLog.args[0]}`);
            }
        } catch (err) {
            // Ignore logs that don't match the NEWADDR event
        }
    }
}

async function deployContract(wallet, name, parameters) {
    Contract = await ethers.getContractFactory(name);
    contract = await Contract.connect(wallet).deploy(...parameters);
    await contract.waitForDeployment();

    console.log(`Deployed ${name} address: ${contract.target}`);

    return contract;

}

async function deployFirewall(wallet, name, transactionEventsLib) {
    let FirewallContract = await ethers.getContractFactory(name, { libraries: { TransactionEventsLib: transactionEventsLib.target } });
    firewallContract = await FirewallContract.connect(wallet).deploy()
    await firewallContract.waitForDeployment()

    console.log(`Deployed NFTFirewallContract address: ${firewallContract.target}`);
    return firewallContract;
}

module.exports = { deployFirewall, getWallet, getAccounts, logNewLines, DeployTransactionEventsLib, logWalletDetails, verifyFirewallContractSetup, getEmittedEvent, deployContract }