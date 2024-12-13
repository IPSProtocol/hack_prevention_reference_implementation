task("hack-erc20", "run the ERC20")
  .addParam("tokens", "The Number of tokens the Hacker will obtain.")
  .setAction(async (taskArgs, hre) => {
    const { tokens } = taskArgs; // Extract lowercase parameter
    const { main } = require("./scripts/nft-reentrancy/run_nft_reentrancy.js");
    await main(tokens, hre);
  });