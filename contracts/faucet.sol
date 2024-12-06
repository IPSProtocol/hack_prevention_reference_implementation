// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Faucet {
    address public owner;
    uint256 public withdrawalAmount;
    uint256 public lockTime;

    mapping(address => uint256) public nextRequestAt;

    event Withdraw(address indexed to, uint256 amount);
    event Deposit(address indexed from, uint256 amount);

    constructor(uint256 _withdrawalAmount, uint256 _lockTime) {
        owner = msg.sender;
        withdrawalAmount = _withdrawalAmount;
        lockTime = _lockTime;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function setWithdrawalAmount(uint256 _withdrawalAmount) public onlyOwner {
        withdrawalAmount = _withdrawalAmount;
    }



    function withdraw() public {
        require(
            nextRequestAt[msg.sender] <= block.timestamp,
            "You have to wait before requesting Ether again."
        );
        require(
            address(this).balance >= withdrawalAmount,
            "Insufficient funds in the faucet."
        );

        nextRequestAt[msg.sender] = block.timestamp + lockTime;
        payable(msg.sender).transfer(withdrawalAmount);
        emit Withdraw(msg.sender, withdrawalAmount);
    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }

}
