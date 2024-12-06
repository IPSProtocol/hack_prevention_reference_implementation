// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./SafeNFT.sol";
import "../IPSFirewall.sol";
import "../TransactionEventsLib.sol";

/// @title NFTFirewallContract is used a firewall contract 
/// @author theexoticman
/// @notice It protects a specific smart contract from hacks. Check IPSChain RC #2 for more details
/// @dev define your security tests in the runSecurityChecks function that is automatically trigger after the transaction ends.
contract NFTFirewallContract is IPSFirewall {    
    
    constructor(){}
    // 79c46aa1e9414f1ec17fe2ddf0a792ed052464f117504d03be80e05734ce37c8
    event ClaimEvent(uint256 indexed claim);  
    event Buy(uint256 indexed nb);
    event Claim(uint256 indexed nb);
    event CouldClaim(uint256 indexed nb);
    
    mapping(address => bool) private couldClaimAccountedFor;
    
    address[] public users;




    /// @notice This function is called by the Decentralized Firewall Engine in the execution client, at the end of the transaction execution if and only if, the contract it is protecting (SafeNFT) is modified.
    /// @dev implement the logic that analyze how your contract behaved
    /// @param caller the EOA who started the call, mostly unused for now.
    /// @param snapshotAddr the address of the snapshot contract, in the same state it was a the beginning of the transacton.
    /// @param contractAddr the actual address of the  contract it is portecting - the SafeNFT, in its the post-tx state. 
    /// @param events The events and parameters emitted during the transaction by the contract this firewall is protecting (SafeNFT). for more details on data structure, check the TransactionEventsLib.sol
    /// for more details on Firewall Contracts and  our Decentralized Firewall check https://docs.ipsprotocol.xyz
    function runSecurityChecks(address caller,  address snapshotAddr, address contractAddr,  TransactionEventsLib.EventData[] memory events ) public  override  {
       
        bytes32 claimEventSig = TransactionEventsLib.getEventHash("Claim(address)");
        bytes32 buyEventSig = TransactionEventsLib.getEventHash("Buy(address)");
    
        uint256  nbClaimEvents=0;
        uint256  nbBuyEvents=0;
        uint256  nbCouldClaim=0;

         

        
        
        // // snapshotContract is the contract state before the transaction started stored temporarly at snapshotAddr.
        SafeNFT snapshotContract = SafeNFT(snapshotAddr);
        
         
        // // currentContract is the current account, with its current state
        SafeNFT currentContract = SafeNFT(contractAddr);
        
        // SafeNFT design allow to buy one NFT at a time - we could check that only on claimed event was emitted.
        // if 2 were found, it meant that user was able to obtain more than 1 
        
        // But let's make it more permissive so that contracts can batch process
        // A User could deploy a contract with the role to iteratively buy and claim
        
        
        
        // A account have started a transaction with the rights to claim
        // bool couldCallerClaim = snapshotContract.canClaim(caller);
        // uint8 nbPrevClaim = (couldCallerClaim == true) ? 1 : 0;
        

        // Logic of the Loop:  calculated how many buying events 
        // claiming events specific to the SafeNFT contract logic
        
        for (uint256 i = 0; i < events.length; i++) {
            // Iterates over all the events produced during the transaction.
            if (snapshotContract.canClaim(events[i].caller)  
                    && couldClaimAccountedFor[events[i].caller]!=true)
                {
                    nbCouldClaim+=1;
                    couldClaimAccountedFor[events[i].caller]=true;
                }
            if (events[i].eventSigHash==claimEventSig){
                // keccak(Transfer(address,address,uint256)) = b449c24d261a59627b537c8c41c57ab559f4205c56bea745ff61c5521bece214
                // Claimed has 1 parameter and it is an address
                // address addr = address(uint160(uint256(events[i].values[0])));
                nbClaimEvents+=1;
            }
            if (events[i].eventSigHash==buyEventSig){
                // to mint several in one transaction, account has to buy, and then claim, by implementatiojn design.
                // keccak(Buy(address)) = 5c6c890314aa0d49059c35b35ff86ffb43efe8f543dc3691558f39dfa4a82011
                // Buy has 1 parameter and it is an address
                // address addr = address(uint160(uint256(events[i].values[0])));
                nbBuyEvents+=1;   
            }
        }

        // logging just in case you want to debug
        emit Buy(nbBuyEvents);
        emit Claim(nbClaimEvents);
        emit CouldClaim(nbCouldClaim);

        if(nbClaimEvents > nbBuyEvents + nbCouldClaim){
            revert("ipschainsecurity: Reentrancy attack detected, reverting transaction");
        }
    }
}
