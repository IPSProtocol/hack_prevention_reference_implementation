# Utility Tokens - ERC20
## Overview

ERC20 is one of the first and most widely adopted standards for crypto assets. It defines a smart contract that represents a token, often associated with being a "cryptocurrency."

This smart contract implements functionalities that allow users to:
- Exchange tokens.
- Grant others permission to transfer tokens on their behalf.

The ERC20 token specification was formalized by the Ethereum community in **EIP-20**:  
[https://eips.ethereum.org/EIPS/eip-20](https://eips.ethereum.org/EIPS/eip-20)

The first implementation of ERC20 was created by **Fabian Vogelsteller** and **Vitalik Buterin** and was used in the DAO project. The first audited implementation of an ERC20 token was the **MakerDAO (MKR)** token in 2017, in collaboration with (Open) Zeppelin. This audit set the foundation for standardized, secure, and audited ERC20 implementations, which today are considered best practices for developers.

---

## Properties

- **Name**: Arbitrary text to identify the token (no specific standard).
- **Symbol**: Typically 3-5 characters, used for display purposes in dApps (e.g., ETH, USDC).
- **Decimals**: Default is 18.  
  This determines the precision of token amounts, critical for financial calculations on-chain. Lower precision (fewer decimals) reduces accuracy in scenarios like buying or selling tokens on decentralized exchanges.

### Examples:
- Bitcoin: 8 decimals.
- Ethereum (ETH): 18 decimals.
- USDT and USDC: 6 decimals.

---

## Functionalities

### **Mint**
Minting allows for the creation of new tokens.  
- Typically, minting is restricted to deployment time to prevent the token owner or users from arbitrarily increasing the supply.  
- Exceptions: Stablecoins often use minting and burning to manage supply, ensuring tokens in circulation are backed by reserves and compliant with regulations (e.g., MiCA).

When tokens are minted:
- The total supply increases by the number of tokens created.

---

### **Burn**
Burning a token removes it from circulation, reducing the total supply.  
This is typically used to:
- Destroy tokens permanently.
- Reflect an updated supply after token removal.

---

### **Transfer**
Transferring tokens can occur in two ways:
1. **Direct Transfer**: The caller sends tokens from their account to a recipient.
2. **TransferFrom**: Allows a caller to transfer tokens from another account, provided they have the required approval.  
   This is fundamental in scenarios where dApps or protocols transfer tokens on behalf of users.

---

### **Approve**
Grants another address the right to manage a specified number of tokens on behalf of the owner.  
- This is critical in DeFi, enabling protocols to execute transactions using user assets seamlessly.

---

## Implementation

**OpenZeppelin** provides a reference implementation and standard contracts that form the foundation for creating your own ERC20 token. You can follow their documentation here:  
[https://docs.openzeppelin.com/contracts/5.x/erc20](https://docs.openzeppelin.com/contracts/5.x/erc20)

---

## Relevant Assets to Protect

### **Token Balance**
Tracks user balances and ensures they are modified only through controlled functions like `transfer`, `mint`, and `burn`.  
Key considerations:
- **Minting**: Ensure users cannot arbitrarily mint tokens to inflate their own balance.
- **Burning**: Prevent unauthorized token destruction.
- **Transfer**: Ensure that users can only transfer tokens from their own account and approved accounts and only if they have a sufficient balance to cover the transfer amount. The function should properly revert the transaction if these conditions are not met.

---

### **Approvals**
Manages user approvals, specifying which addresses can transfer tokens on their behalf and how much.  
Key considerations:
- Ensure no unauthorized modifications to user approvals.
- Update the approvals according to users actions. 



## Attack Vectors


| **Asset to Protect** | **Attack Vector**                                                                                                                                                          | **Description**                                                                                                                                                                                                                                                                     |
|-----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Token Balance**     | Unauthorized Minting                                                                                                                                                     | An attacker could exploit vulnerabilities in the mint function to create tokens and increase their balance without proper authorization.                                                                                                                                            |
|                       | Unauthorized Burning                                                                                                                                                     | An attacker could exploit the burn function to destroy tokens arbitrarily, affecting balances incorrectly.                                                                                                                                                                         |
|                       | Direct Balance Manipulation                                                                                                                                             | An attacker could bypass transfer, mint, or burn functions and directly modify user balances in storage.                                                                                                                                                                          |
|                       | Overflow/Underflow                                                                                                                                                       | Arithmetic vulnerabilities (e.g., integer overflow or underflow) could lead to incorrect balance calculations.                                                                                                                                                                   |
|                       | Reentrancy Attacks                                                                                                                                                       | Exploiting reentrancy to call contract methods in unintended sequences, potentially affecting balances during transactions.                                                                                                                                                       |
|                       | Replay Attacks                                                                                                                                                           | Reusing signed transactions or data to execute transfers multiple times.                                                                                                                                                                                                          |
| **Approvals**         | Unauthorized Approval Modification                                                                                                                                       | An attacker could alter the `allowance` of a user without authorization.                                                                                                                                                                                                          |
|                       | Insufficient Approval Checks                                                                                                                                            | Failing to validate that the address modifying approvals has the right permissions.                                                                                                                                                                                              |
|                       | Reentrancy Attacks                                                                                                                                                       | Exploiting approval-related functions in unintended sequences to alter allowances.                                                                                                                                                                                               |
|                       | Approval Race Conditions                                                                                                                                                 | Exploiting race conditions between `approve` and `transferFrom` to steal tokens.                                                                                                                                                                                                 |
|                       | Approval Replay Attacks                                                                                                                                                  | Reusing outdated signed data to modify approvals in unexpected ways.                                                                                                                                                                                                             |
|                       | Excessive Approvals                                                                                                                                                      | Users mistakenly approving unlimited amounts (`2^256 - 1`), leaving their funds vulnerable to misuse.                                                                                                                                                                            |

## Security Mechanisms

| **Asset to Protect** | **Attack Vector**                          | **Security Function**                                                                                                                                                              |
|-----------------------|--------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Token Balance**     | Unauthorized Minting                      | Implementing access control (e.g., `onlyOwner` modifier) to restrict who can mint tokens.                                                                                          |
|                       | Unauthorized Burning                      | Implementing access control to allow only the owner of tokens to burn their tokens.                                                                                                |
|                       | Direct Balance Manipulation               | Avoiding setter functions; balances can only be modified through controlled functions (`transfer`, `mint`, `burn`).                                                               |
|                       | Overflow/Underflow                        | Handled by Solidity version ≥ 0.8, where arithmetic overflow and underflow are checked automatically.                                                                              |
|                       | Replay Attacks                            | Protected by blockchain mechanisms, including transaction authentication with a nonce and `chainID`.                                                                               |
|                       | Reentrancy Attacks                        | The ERC-20 standard implementation avoids external contract calls during transactions, preventing reentrancy attacks.                                                              |
| **Approvals**         | Unauthorized Approval Modification        | Approvals can only be changed via the `approve` function; access control prevents unauthorized modification of other users' approvals.                                              |
|                       | Overflow/Underflow                        | Handled by Solidity version ≥ 0.8, where arithmetic overflow and underflow are checked automatically.                                                                              |
|                       | Reentrancy Attacks                        | The ERC-20 standard implementation avoids external contract calls during approval functions, mitigating reentrancy attack vectors.                                                 |
|                       | Approval Replay Attacks                   | Protected by blockchain mechanisms, including transaction authentication with a nonce and `chainID`.                                                                               |




## ERC20 Invariants

Invariants are the foundational rules and conditions that define how software should behave under all circumstances. These formulas and conditions must always hold true, regardless of the type of transaction. They serve as the formal specifications of the application, outlining exactly how the software should function. If any invariant is violated, it indicates a critical flaw or a broken condition in the system.

Invariants are a crucial aspect of fuzzing and formal verification campaigns—the most advanced and technically rigorous approaches for automating the detection of bugs and vulnerabilities. However, these methodologies have limitations: they cannot test all possible cases due to the infinite number of potential scenarios in complex systems.

Firewall Contracts address these limitations by dynamically validating invariants for every single transaction. These contracts ensure that no transaction violates the defined invariants of the crypto asset. If an invariant is broken, it signals that the transaction exploited the crypto asset’s code in a way that was not intended—indicating non-compliant or malicious usage of the exposed service. Consequently, we can reliably conclude that such a transaction should not proceed.

Firewall Contracts dynamically and proactively revert non-compliant transactions before they are added to the blockchain. This decision-making process is fully transparent, as it is executed within the Ethereum Virtual Machine (EVM) and the results are published on-chain. Thanks to the deterministic nature of smart contract execution, anyone can re-execute the transaction, investigate, and obtain the same result, ensuring transparency and trust in the system.

By embedding invariant checks into Firewall Contracts, this approach not only strengthens the security of ERC-20 tokens but also offers a robust, on-chain mechanism for preventing unauthorized or unintended behaviors.


### An Example of ERC20 Invariants

#### **Transfer Integrity**
When Alice transfers X tokens to Bob, the following rules must always apply to ensure correctness:

1. **Total User Balance Sum**:  
   The total sum of balances across all users should remain the same. No tokens should be created or destroyed during the transfer process.

2. **Alice's New Balance**:  
   Alice's new balance should equal her old balance minus X, provided her balance is sufficient. If her balance is insufficient, the transfer should fail.

3. **Bob's New Balance**:  
   Bob's balance should increase by X, reflecting the amount transferred.

These three properties ensure that the transfer function is implemented correctly, maintaining the integrity of token balances.

Additionally, since the **zero address (0x0)** is a special address used for burning tokens, the following additional rules should apply:

- Neither Alice's nor Bob's address can be the zero address (0x0).  
- If Alice intends to send tokens to the zero address (burn tokens), the transfer should not proceed. Instead, a dedicated **burn function** must be used for this purpose.

---

### Creating the Vulnerability

To demonstrate how vulnerabilities might arise in the implementation, let's intentionally remove some of the fundamental security mechanisms. This will help highlight how Firewall Contracts and their invariant-based tests can detect and mitigate unintended behaviors.

#### **Example Vulnerability**
Let's remove the **access control** in the `transfer` function. Without this protection, users could:

- Manipulate other users' balances by transferring tokens they don't own.

This lack of security creates a scenario where unauthorized actions are possible, breaking key invariants of the ERC20 implementation.

---

### Implementing the Firewall Contract

A **Firewall Contract** dynamically validates invariants for every transaction, even in the absence of fundamental security mechanisms. Here's how it addresses vulnerabilities:

- **Total User Balance Integrity**:  
  Ensures the total sum of user balances remains constant during transfers, preventing unauthorized minting or burning.

- **Ownership Validation**:  
  Verifies that the sender has sufficient tokens to complete the transfer, ensuring they cannot transfer more than they own.

- **Updated Balances**:  
  Checks that both the sender's and receiver's balances are updated correctly based on the transfer amount, maintaining accuracy.

- **Zero Address Protection**:  
  Ensures that neither the sender nor the receiver is the zero address (`0x0`) unless the burn function is explicitly invoked.

By embedding these checks, the Firewall Contract proactively mitigates vulnerabilities, reverting any transaction that violates the defined invariants before it is added to the blockchain. This approach ensures robust, dynamic protection against unintended or malicious behaviors.

---

### Implementation Workflow

The following changes will be applied to the contracts:

1. **VulnERC20.sol**:  
   - Represents a vulnerable ERC-20 token implementation where fundamental security mechanisms are intentionally omitted, such as access control in the `transfer` function.

2. **VulnERC20FirewallContract.sol**:  
   - Implements the Firewall Contract logic to protect the `transfer` function by dynamically validating all invariants.

The **Firewall Contract** acts as a safeguard, ensuring compliance with the defined security rules and providing a transparent and deterministic layer of protection for transactions.
