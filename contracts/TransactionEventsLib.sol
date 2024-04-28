// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

library TransactionEventsLib {
    
    struct EventData {
        bytes32 eventSigHash;
        bytes32[] parameters;
        address msgSender;
    }

    function getEventHash(string memory functionSig) public pure returns (bytes32) {
        // Event signature and parameter types
           bytes32 hash = keccak256(abi.encodePacked(functionSig));
        
        return hash;
    }

}
