const { ethers } = require("hardhat");

async function main() {
  const addresses = {
    moto: process.argv[2],
    buyback: process.argv[3], 
    vault: process.argv[4]
  };

  if (!addresses.moto || !addresses.buyback || !addresses.vault) {
    console.log("Usage: node post-deploy.js <moto> <buyback> <vault>");
    return;
  }

  const [deployer] = await ethers.getSigners();
  const moto = await ethers.getContractAt("MotoToken", addresses.moto);
  
  console.log("🔧 Post-deployment configuration...");
  
  // Set BaseSwap as fee exempt
  await moto.setFeeExemption("0x327Df1E6de05895d2ab08513aaDD9313Fe505d86", true);
  console.log("✅ BaseSwap router fee exempt");
  
  // Verify configuration
  const buybackContract = await moto.buybackContract();
  const vaultContract = await moto.vaultContract();
  
  console.log("📋 Contract Configuration:");
  console.log("MotoToken:", addresses.moto);
  console.log("Buyback:", buybackContract);
  console.log("Vault:", vaultContract);
  console.log("Owner:", await moto.owner());
  
  console.log("\n🎉 Ready for liquidity addition!");
}

main().catch(console.error);