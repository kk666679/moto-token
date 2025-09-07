import pkg from "hardhat";
const { ethers } = pkg;

async function main() {
  console.log("🚀 Deploying to Base Sepolia testnet...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);
  
  // Deploy MotoToken
  const MotoToken = await ethers.getContractFactory("MotoToken");
  const motoToken = await MotoToken.deploy(deployer.address);
  await motoToken.waitForDeployment();
  const motoAddress = await motoToken.getAddress();
  
  // Deploy Buyback
  const Buyback = await ethers.getContractFactory("Buyback");
  const buyback = await Buyback.deploy(
    motoAddress,
    "0x327Df1E6de05895d2ab08513aaDD9313Fe505d86", // BaseSwap router
    deployer.address
  );
  await buyback.waitForDeployment();
  const buybackAddress = await buyback.getAddress();
  
  // Deploy Vault
  const Vault = await ethers.getContractFactory("AccumulatingVault");
  const vault = await Vault.deploy(
    motoAddress,
    "0x327Df1E6de05895d2ab08513aaDD9313Fe505d86",
    deployer.address
  );
  await vault.waitForDeployment();
  const vaultAddress = await vault.getAddress();
  
  // Configure contracts
  await motoToken.setContracts(buybackAddress, vaultAddress);
  
  console.log("✅ Deployment complete!");
  console.log("MotoToken:", motoAddress);
  console.log("Buyback:", buybackAddress);
  console.log("Vault:", vaultAddress);
  
  // Verification commands
  console.log("\n📋 Verify with:");
  console.log(`npx hardhat verify --network base-sepolia ${motoAddress} "${deployer.address}"`);
  console.log(`npx hardhat verify --network base-sepolia ${buybackAddress} "${motoAddress}" "0x327Df1E6de05895d2ab08513aaDD9313Fe505d86" "${deployer.address}"`);
  console.log(`npx hardhat verify --network base-sepolia ${vaultAddress} "${motoAddress}" "0x327Df1E6de05895d2ab08513aaDD9313Fe505d86" "${deployer.address}"`);
}

main().catch(console.error);