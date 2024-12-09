// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {BLERC20} from "./ERC20_BL_only.sol";

//  BLERC20 implementing only the Business Logic, without all the security checks.
contract MyBLERC20 is BLERC20 {
    constructor(uint256 initialSupply) BLERC20("MyBLERC20", "BLT") {
        _mint(msg.sender, initialSupply);
    }
}