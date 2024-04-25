// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./TransactionEventsLib.sol";
// import "./Mycontract.sol" // import the contract your want to protect so that you can instantiate and compare the snapshot with the current contract.;

abstract contract IPSFirewall {
    
    // @notice This function is triggered by the Decentralized Firewall and is responsible for analyzing transaction behavior to protect the source contract; it reverts upon detecting malicious behavior, allowing only non-reverted transactions to proceed.
    /// @dev Add any logic that will allow the detection of malicious behavior; the list of emitted events and access to your contract, as well as a snapshot version of it from before the start of the transaction, should be enough to determine suspicious activities.
    /// @param caller The externally owned account (EOA) responsible for initiating the transaction.
    /// @param snapshotAddr The address of a temporary snapshot of the protected contract, representing the state of the contract at the beginning of the transaction.
    /// @param contractAddr The address of the actual contract under protection.
    /// @param events A list of events emitted by the protected contract during the transaction execution.
    function runSecurityChecks(address caller, address snapshotAddr, address contractAddr, TransactionEventsLib.EventData[] memory events) public virtual;

    /// @notice This function ensures that IPSFirewalls are correctly recognized.
    /// @dev The only way for us to enforce that the correct functions are implemented in their firewall so that protected contracts have their firewall run.
    /// @return static value which shouldn't change
    function IPSProtocolUUID() public pure returns (bytes32) {
        return 0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f;
    }
    // Code position in storage is keccak256("IPSProtocol") = "0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f"
}