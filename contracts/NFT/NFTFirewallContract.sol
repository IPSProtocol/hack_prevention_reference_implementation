// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./VulnNFT.sol";
import "../IPSFirewall.sol";
import "../TransactionEventsLib.sol";

/// @title NFTFirewallContract is used a firewall contract
/// @author theexoticman
/// @notice It protects a specific smart contract from hacks. Check IPSChain RC #2 for more details
/// @dev define your security tests in the runFirewallContract function that is automatically trigger after the transaction ends.
contract NFTFirewallContract is IPSFirewall {
    constructor() {}

    // invariant variable
    mapping(address => bool) public canClaim;
    address public caller;
    address public buyer;
    bytes32 public buyerBytes;
    address public claimer;
    uint public length;

    bytes32 claimEventSig = TransactionEventsLib.getEventHash("Claim(address)");
    bytes32 buyEventSig = TransactionEventsLib.getEventHash("Buy(address)");
    bytes32 transferEventSig =
        TransactionEventsLib.getEventHash("Tansfer(address,address,value)");

    /// @notice This function is called by the Decentralized Firewall Engine in the execution client, at the end of the transaction execution if and only if, the contract it is protecting (VulnNFT) is modified.
    /// @dev implement the logic that analyze how your contract behaved
    /// @param caller the EOA who started the call, mostly unused for now.
    /// @param snapshotAddr the address of the snapshot contract, in the same state it was a the beginning of the transacton.
    /// @param contractAddr the actual address of the  contract it is portecting - the VulnNFT, in its the post-tx state.
    /// @param events The events and parameters emitted during the transaction by the contract this firewall is protecting (VulnNFT). for more details on data structure, check the TransactionEventsLib.sol
    /// for more details on Firewall Contracts and  our Decentralized Firewall check https://docs.ipsprotocol.xyz
    function runFirewallContract(
        address caller,
        address snapshotAddr,
        address contractAddr,
        TransactionEventsLib.EventData[] memory events
    ) public override {
        for (uint256 i = 0; i < events.length; i++) {
            TransactionEventsLib.EventData memory thisEvent = events[i];
            if (isBuyEvent(thisEvent)) {
                processBuyEvent(thisEvent);
            } else if (isClaimEvent(thisEvent)) {
                processClaimEvent(thisEvent);
            }
        }
    }

    function isBuyEvent(
        TransactionEventsLib.EventData memory thisEvent
    ) internal view returns (bool) {
        return thisEvent.eventSigHash == buyEventSig;
    }

    function isClaimEvent(
        TransactionEventsLib.EventData memory thisEvent
    ) internal view returns (bool) {
        return thisEvent.eventSigHash == claimEventSig;
    }

    function processBuyEvent(
        TransactionEventsLib.EventData memory thisEvent
    ) internal {
        // logic of the buy event
        address _buyer = address(uint160(uint256(thisEvent.parameters[0])));
        buyer = _buyer;
        caller = thisEvent.caller;
        length = thisEvent.parameters.length;
        buyerBytes = thisEvent.parameters[0];
        // update the invariant variable
        canClaim[_buyer] = true;
    }

    function processClaimEvent(
        TransactionEventsLib.EventData memory thisEvent
    ) internal {
        // logic of the buy event
        claimer = address(uint160(uint256(thisEvent.parameters[0])));
        // update the invariant variable

        if (canClaim[claimer]) {
            // update the claim rights
            canClaim[claimer] = false;
        } else {
            // claimer has not right to claim
            revert(
                "DecentralizedFirewall: Invariant: Should Buy Before Claiming"
            );
        }
    }
}
