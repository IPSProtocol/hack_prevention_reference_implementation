task("hack-erc20", "run the ERC20")
  .setAction(async (taskArgs, hre) => {
    // const { tokens } = taskArgs; // Extract lowercase parameter
    const { main } = require("../scripts/vuln-erc20/run_vuln_erc20_hack.js");
    await main( hre);
  });