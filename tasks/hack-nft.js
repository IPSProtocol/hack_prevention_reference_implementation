task("hack-nft", "run the nft hack flow")
  .addParam("tokens", "The Number of tokens the Hacker will obtain.")
  .setAction(async (taskArgs, hre) => {
    const { tokens } = taskArgs; // Extract lowercase parameter
    // Validate tokens with meaningful feedback
    if (tokens <= 0 || tokens >= 61) {
      console.error("Error: The number of tokens must be between 1 and 60.");
      return; // Exit the task early if invalid
    }
    const { main } = require("../scripts/nft-reentrancy/run_nft_reentrancy.js");
    await main(tokens, hre);
  });