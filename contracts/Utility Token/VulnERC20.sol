// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {ERC20} from "./ERC20.sol";

contract VulnERC20 is ERC20 {
    constructor(uint256 initialSupply) ERC20("VulnERC20", "V20") {
        _mint(msg.sender, initialSupply);
    }
}