import { ethers } from "hardhat";

async function main() {
  console.log("🚨 MAINNET DEPLOYMENT - Base Network");
  console.log("⚠️  Ensure you have:");
  console.log("   - Sufficient ETH for deployment");
  console.log("   - Verified contract code");
  console.log("   - Multi-sig wallet ready");
  
  const [deployer] = await ethers.getSigners();
  const balance = await deployer.provider.getBalance(deployer.address);
  
  console.log("Deployer:", deployer.address);
  console.log("Balance:", ethers.formatEther(balance), "ETH");
  
  if (balance < ethers.parseEther("0.1")) {
    throw new Error("Insufficient ETH for deployment");
  }
  
  // Deploy contracts
  const MotoToken = await ethers.getContractFactory("MotoToken");
  const motoToken = await MotoToken.deploy(deployer.address);
  await motoToken.waitForDeployment();
  
  const Buyback = await ethers.getContractFactory("Buyback");
  const buyback = await Buyback.deploy(
    await motoToken.getAddress(),
    "0x327Df1E6de05895d2ab08513aaDD9313Fe505d86",
    deployer.address
  );
  await buyback.waitForDeployment();
  
  const Vault = await ethers.getContractFactory("AccumulatingVault");
  const vault = await Vault.deploy(
    await motoToken.getAddress(),
    "0x327Df1E6de05895d2ab08513aaDD9313Fe505d86",
    deployer.address
  );
  await vault.waitForDeployment();
  
  // Configure
  await motoToken.setContracts(await buyback.getAddress(), await vault.getAddress());
  
  console.log("🎉 MAINNET DEPLOYMENT SUCCESSFUL!");
  console.log("MotoToken:", await motoToken.getAddress());
  console.log("Buyback:", await buyback.getAddress());
  console.log("Vault:", await vault.getAddress());
}

main().catch(console.error);