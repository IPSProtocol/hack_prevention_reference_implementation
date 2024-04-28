// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./IPSFirewall.sol";

/// @title Interface for protecting business logic contracts
/// @author Theexoticman
/// @notice a standard way for managing the firewall contract
/// @dev Explain to a developer any extra details
abstract contract IPSFirewallProtected {

    bytes32 firewallSlot = 0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f;
    address owner;
    constructor(){
        owner = msg.sender;
    }
    /// @notice Updates the address of the firewall contract responsible for the protection of this contract
    /// @dev it checks that the firewall implements the IPSFirewall Contract
    /// @param newAddress the firewall contract new address
    function updateFirewallAddress(address newAddress) internal onlyOwner{
        require(
            bytes32(0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f) == IPSFirewall(newAddress).IPSProtocolUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f, newAddress)
        }
    }
    
    function getSlot() public view returns (bytes32) {
        return firewallSlot;
    }

    /// @notice Gets the firewall contract address protecting this cotnract
    /// @return addr the address of the associated firewall contract
    function getFirewallAddress() public view returns (address addr) {
        assembly {
            let location := 0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f
            addr := sload(location)
        }
        return addr;
    }

       modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed to perform this action");
        _;
    }

}