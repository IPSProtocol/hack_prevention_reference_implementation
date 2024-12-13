// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {VulnERC20} from "./ERC20_BL_only.sol";
import "../IPSFirewallProtected.sol";

//  VulnERC20 implementing only the Business Logic, without all the security checks.
contract MyVulnERC20 is VulnERC20, IPSFirewallProtected {
    constructor(
        uint256 initialSupply,
        address firewallAddress
    ) VulnERC20("MyVulnERC20", "BLT") IPSFirewallProtected(firewallAddress) {
        _mint(msg.sender, initialSupply);
    }
}
