const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Input sanitization helper
function sanitizeInput(input) {
  return String(input).replace(/[\r\n\t]/g, ' ').substring(0, 100);
}

// Safe JSON parsing
function safeJsonParse(data) {
  try {
    return JSON.parse(data);
  } catch (error) {
    throw new Error('Invalid JSON format in deployment file');
  }
}

async function main() {
  const deploymentFile = process.argv[2];
  
  if (!deploymentFile) {
    console.error("Usage: npx hardhat run scripts/verify.js --network <network> <deployment-file>");
    process.exit(1);
  }
  
  if (!fs.existsSync(deploymentFile)) {
    console.error("Deployment file not found:", deploymentFile);
    process.exit(1);
  }
  
  const deploymentData = safeJsonParse(fs.readFileSync(deploymentFile, "utf8"));
  const { contracts, config } = deploymentData;
  
  console.log("Verifying contracts from deployment:", sanitizeInput(deploymentFile));
  
  try {
    // Verify MotoToken
    console.log("\n1. Verifying MotoToken...");
    await hre.run("verify:verify", {
      address: contracts.motoToken,
      constructorArguments: [config.initialOwner],
    });
    console.log("✅ MotoToken verified");
    
    // Verify Buyback
    console.log("\n2. Verifying Buyback...");
    await hre.run("verify:verify", {
      address: contracts.buyback,
      constructorArguments: [
        contracts.motoToken,
        config.baseSwapRouter,
        config.initialOwner,
      ],
    });
    console.log("✅ Buyback verified");
    
    // Verify AccumulatingVault
    console.log("\n3. Verifying AccumulatingVault...");
    await hre.run("verify:verify", {
      address: contracts.vault,
      constructorArguments: [
        contracts.motoToken,
        config.baseSwapRouter,
        config.initialOwner,
      ],
    });
    console.log("✅ AccumulatingVault verified");
    
    // Verify LiquidityLocker
    console.log("\n4. Verifying LiquidityLocker...");
    await hre.run("verify:verify", {
      address: contracts.liquidityLocker,
      constructorArguments: [config.initialOwner],
    });
    console.log("✅ LiquidityLocker verified");
    
    console.log("\n🎉 All contracts verified successfully!");
    
  } catch (error) {
    console.error("❌ Verification failed:", error);
    process.exit(1);
  }
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = { main };

