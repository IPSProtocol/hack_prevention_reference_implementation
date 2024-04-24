# NFT Reentrancy Attack

This exploit scenario leverages a vulnerability in SafeNFT. Specifically, SafeNFT is an NFT that receives a gas token (1) and grants a user the right to claim another token. It involves a two-step transaction. In the first step, the user sends funds to the buy function. In the second step, the user calls the claim function. If the caller is authorized, SafeNFT mints a new token for that user.

However, the claim function may be susceptible to a reentrancy attack. According to the ERC721 standard, whenever an NFT is transferred to an address, it checks if that address implements the `onERC721Received` function. This ensures that the address knows how to handle such a type of crypto asset.

Using this setup, a hacker can initiate another call to the claim function from within the onERC721Received function, as demonstrated [here](https://github.com/IPSProtocol/hack_prevention_reference_implementation/blob/main/contracts/nft-reentrancy/NftHack.sol#L22-L43)