// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract SafeNFT is ERC721Enumerable {
    uint256 price;
    mapping(address=>bool) public canClaim;
    event Buy(address buyer);
    event SetSSC(bytes32 storageSlot,address ssc);
    event Claimed(address buyer);

    constructor(address smartContractSecurityAddress ,string memory tokenName, string memory tokenSymbol,uint256 _price) ERC721(tokenName, tokenSymbol) {
        setAddressAtSlot(smartContractSecurityAddress);
        price = _price; //price = 0.01 ETH
    }

    // This function sets an address at a specific storage slot
    function setAddressAtSlot(address _address) public returns (address addr) {
        bytes32 slot = getSlot();
        assembly {
            // Calculate the storage location using keccak256
            let location := 0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f // keccak256("IPSPROTOCOL")
            // Set the address at the specified location
            sstore(location, _address)
        }
        emit SetSSC(slot,_address);
        return getAddressFromSlot();

    }

    function getSlot() public pure returns (bytes32) {
        return keccak256(abi.encodePacked("IPSPROTOCOL"));
    }

    function getAddressFromSlot() public view returns (address addr) {
        assembly {
            let location := 0xf5db7be7144a933071df54eb1557c996e91cbc47176ea78e1c6f39f9306cff5f
            addr := sload(location)
        }
        return addr;
    }
    function buyNFT() external payable {
        require(price==msg.value,"INVALID_VALUE");
        canClaim[msg.sender] = true;
        emit Buy(msg.sender);
    }

    function claim() external {
        require(canClaim[msg.sender],"CANT_MINT");
        _safeMint(msg.sender, totalSupply()); 
        canClaim[msg.sender] = false;
        emit Claimed(msg.sender);
    }
 
}
