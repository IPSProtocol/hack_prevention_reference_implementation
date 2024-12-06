// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../IPSFirewallProtected.sol";

contract SafeNFT is ERC721Enumerable,  IPSFirewallProtected {
    uint256 price;
    mapping(address=>bool) public canClaim;
    event Buy(address buyer);
    event Claim(address buyer);

    constructor(address firewallAddress ,string memory tokenName, string memory tokenSymbol,uint256 _price) ERC721(tokenName, tokenSymbol) IPSFirewallProtected(firewallAddress) {
        price = _price; //price = 0.01 ETH
    }

    function buy() external payable {
        require(msg.value>=price,"NOT_ENOUGH_FUNDS");
        canClaim[msg.sender] = true;
        emit Buy(msg.sender);
    }

    function claim() external {
        require(canClaim[msg.sender],"USER_CANT_MINT_BUY_FIRST");
        _safeMint(msg.sender, totalSupply()); 
        canClaim[msg.sender] = false;
        emit Claim(msg.sender);
    }
 
}
