// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./SafeNFT.sol";
import "../TransactionEventsLib.sol";

/// @title NFTFirewallContract is used a firewall contract 
/// @author theexoticman
/// @notice It protects a specific smart contract from hacks. Check IPSChain RC #2 for more details
/// @dev define your security tests in the runSecurityChecks function that is automatically trigger after the transaction ends.
contract NFTFirewallContract{    
    
    constructor(){}
    // 79c46aa1e9414f1ec17fe2ddf0a792ed052464f117504d03be80e05734ce37c8
    event ClaimEvent(uint256 indexed claim);
    // 3e405113778d3b96e0eab3ae46f24133b1165b037116937e810c384bcbcfdff7
    event BuyEvent(uint256 indexed buy);
    event CurrentEvent(bytes32 indexed found, bytes32 indexed expected);

    /// @notice This function is called by the Decentralized Firewall at the end of the transaction execution if and only if, the contract it is protecting (SafeNFT) is modified.
    /// @dev implement the logic that analyze how your contract behaved
    /// @param caller the EOA who started the call, mostly unused for now.
    /// @param snapshotAddr the address of the snapshot contract, in the same state it was a the beginning of the transacton.
    /// @param contractAddr the actual address of the  contract it is portecting - the SafeNFT, in its the post-tx state. 
    /// @param events The events and parameters emitted during the transaction by the contract this firewall is protecting (SafeNFT). for more details on data structure, check the TransactionEventsLib.sol
    /// for more details on Firewall Contracts and  our Decentralized Firewall check https://docs.ipsprotocol.xyz
    function runSecurityChecks(address caller,  address snapshotAddr, address contractAddr,  TransactionEventsLib.EventData[] memory events ) public   {

        bytes32 claimedEventSig = TransactionEventsLib.getEventHash("Claimed(address)");
        bytes32 buyEventSig = TransactionEventsLib.getEventHash("Buy(address)");
    
        uint  nbClaimedEvents=0;
        uint  nbBuyEvents=0;

        // snapshotContract is the contract state before the transaction started stored temporarly at snapshotAddr.
        SafeNFT snapshotContract = SafeNFT(snapshotAddr);
        
        // currentContract is the current contract, with its current state
        SafeNFT currentContract = SafeNFT(contractAddr);
        
        // SafeNFT design allow to buy one NFT at a time - we could check that only on claimed event was emitted.
        // if 2 were found, it meant that user was able to obtain more than 1 
        
        // But let's make it more permissive so that contracts can batch process
        // A User could deploy a contract with the role to iteratively buy and claim
        
        
        // A account have started a transaction with the rights to claim
        bool couldCallerClaim = snapshotContract.canClaim(caller);
        uint8 nbPrevClaim = (couldCallerClaim == true) ? 1 : 0;
        
        for (uint256 i = 0; i < events.length; i++) {
            // Iterates over all the events produced during the transaction.
            if (events[i].eventSigHash==claimedEventSig){
                // keccak(Transfer(address,address,uint256)) = b449c24d261a59627b537c8c41c57ab559f4205c56bea745ff61c5521bece214
                // Claimed has 1 parameter and it is an address
                // address addr = address(uint160(uint256(events[i].values[0])));

                nbClaimedEvents+=1;
            }
            if (events[i].eventSigHash==buyEventSig){
                // to mint several in one transaction, account has to buy, and then claim, by implementatiojn design.
                // keccak(Buy(address)) = 5c6c890314aa0d49059c35b35ff86ffb43efe8f543dc3691558f39dfa4a82011
                // Buy has 1 parameter and it is an address
                // address addr = address(uint160(uint256(events[i].values[0])));
                nbBuyEvents+=1;   
            }
        }
        emit BuyEvent(nbBuyEvents);
        emit ClaimEvent(nbClaimedEvents);
        if(nbClaimedEvents > nbBuyEvents + nbPrevClaim){
            revert("ipschainsecurity: Reentrancy attack detected, reverting transaction");
        }
    }
}
