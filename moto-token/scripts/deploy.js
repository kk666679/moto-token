const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("Starting Moto Token deployment...");
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  
  const balance = await deployer.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "ETH");
  
  // Deployment configuration
  const config = {
    initialOwner: deployer.address,
    baseSwapRouter: "0x327Df1E6de05895d2ab08513aaDD9313Fe505d86",
    initialLiquidityETH: process.env.INITIAL_LIQUIDITY_ETH || "1.0",
    initialLiquidityTokensPercent: process.env.INITIAL_LIQUIDITY_TOKENS_PERCENT || "80",
  };
  
  console.log("Deployment configuration:", config);
  
  // Deploy contracts
  const deploymentResults = {};
  
  try {
    // 1. Deploy MotoToken
    console.log("\n1. Deploying MotoToken...");
    const MotoToken = await ethers.getContractFactory("MotoToken");
    const motoToken = await MotoToken.deploy(config.initialOwner);
    await motoToken.waitForDeployment();
    const motoTokenAddress = await motoToken.getAddress();
    console.log("MotoToken deployed to:", motoTokenAddress);
    deploymentResults.motoToken = motoTokenAddress;
    
    // 2. Deploy Buyback contract
    console.log("\n2. Deploying Buyback contract...");
    const Buyback = await ethers.getContractFactory("Buyback");
    const buyback = await Buyback.deploy(
      motoTokenAddress,
      config.baseSwapRouter,
      config.initialOwner
    );
    await buyback.waitForDeployment();
    const buybackAddress = await buyback.getAddress();
    console.log("Buyback deployed to:", buybackAddress);
    deploymentResults.buyback = buybackAddress;
    
    // 3. Deploy AccumulatingVault contract
    console.log("\n3. Deploying AccumulatingVault contract...");
    const AccumulatingVault = await ethers.getContractFactory("AccumulatingVault");
    const vault = await AccumulatingVault.deploy(
      motoTokenAddress,
      config.baseSwapRouter,
      config.initialOwner
    );
    await vault.waitForDeployment();
    const vaultAddress = await vault.getAddress();
    console.log("AccumulatingVault deployed to:", vaultAddress);
    deploymentResults.vault = vaultAddress;
    
    // 4. Deploy LiquidityLocker contract
    console.log("\n4. Deploying LiquidityLocker contract...");
    const LiquidityLocker = await ethers.getContractFactory("LiquidityLocker");
    const liquidityLocker = await LiquidityLocker.deploy(config.initialOwner);
    await liquidityLocker.waitForDeployment();
    const liquidityLockerAddress = await liquidityLocker.getAddress();
    console.log("LiquidityLocker deployed to:", liquidityLockerAddress);
    deploymentResults.liquidityLocker = liquidityLockerAddress;
    
    // 5. Configure MotoToken with auxiliary contracts
    console.log("\n5. Configuring MotoToken with auxiliary contracts...");
    const setContractsTx = await motoToken.setContracts(buybackAddress, vaultAddress);
    await setContractsTx.wait();
    console.log("MotoToken configured with auxiliary contracts");
    
    // 6. Add initial liquidity (if on mainnet or testnet)
    const network = await ethers.provider.getNetwork();
    if (network.chainId !== 1337n) { // Not hardhat local network
      console.log("\n6. Adding initial liquidity...");
      await addInitialLiquidity(
        motoToken,
        config.baseSwapRouter,
        config.initialLiquidityETH,
        config.initialLiquidityTokensPercent,
        deployer
      );
    } else {
      console.log("\n6. Skipping liquidity addition on local network");
    }
    
    // 7. Save deployment results
    const deploymentData = {
      network: network.name,
      chainId: network.chainId.toString(),
      deployer: deployer.address,
      timestamp: new Date().toISOString(),
      contracts: deploymentResults,
      config: config,
    };
    
    const deploymentFile = path.join(__dirname, "..", "deployments", `${network.name}-${Date.now()}.json`);
    fs.mkdirSync(path.dirname(deploymentFile), { recursive: true });
    fs.writeFileSync(deploymentFile, JSON.stringify(deploymentData, null, 2));
    
    console.log("\n✅ Deployment completed successfully!");
    console.log("Deployment data saved to:", deploymentFile);
    console.log("\nContract addresses:");
    console.log("- MotoToken:", motoTokenAddress);
    console.log("- Buyback:", buybackAddress);
    console.log("- AccumulatingVault:", vaultAddress);
    console.log("- LiquidityLocker:", liquidityLockerAddress);
    
    // 8. Verification instructions
    console.log("\n📋 Contract verification commands:");
    console.log(`npx hardhat verify --network ${network.name} ${motoTokenAddress} "${config.initialOwner}"`);
    console.log(`npx hardhat verify --network ${network.name} ${buybackAddress} "${motoTokenAddress}" "${config.baseSwapRouter}" "${config.initialOwner}"`);
    console.log(`npx hardhat verify --network ${network.name} ${vaultAddress} "${motoTokenAddress}" "${config.baseSwapRouter}" "${config.initialOwner}"`);
    console.log(`npx hardhat verify --network ${network.name} ${liquidityLockerAddress} "${config.initialOwner}"`);
    
  } catch (error) {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  }
}

async function addInitialLiquidity(motoToken, routerAddress, liquidityETH, tokensPercent, deployer) {
  try {
    // Get router contract
    const routerABI = [
      "function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity)"
    ];
    const router = new ethers.Contract(routerAddress, routerABI, deployer);
    
    // Calculate token amount for liquidity
    const totalSupply = await motoToken.totalSupply();
    const tokenAmount = (totalSupply * BigInt(tokensPercent)) / 100n;
    
    // Approve router to spend tokens
    console.log("Approving router to spend tokens...");
    const approveTx = await motoToken.approve(routerAddress, tokenAmount);
    await approveTx.wait();
    
    // Add liquidity
    const ethAmount = ethers.parseEther(liquidityETH);
    const deadline = Math.floor(Date.now() / 1000) + 300; // 5 minutes
    
    console.log(`Adding liquidity: ${ethers.formatEther(tokenAmount)} MOTO + ${liquidityETH} ETH`);
    const addLiquidityTx = await router.addLiquidityETH(
      await motoToken.getAddress(),
      tokenAmount,
      tokenAmount * 95n / 100n, // 5% slippage tolerance
      ethAmount * 95n / 100n,   // 5% slippage tolerance
      deployer.address,
      deadline,
      { value: ethAmount }
    );
    
    const receipt = await addLiquidityTx.wait();
    console.log("Liquidity added successfully! Transaction hash:", receipt.hash);
    
  } catch (error) {
    console.error("Failed to add initial liquidity:", error);
    throw error;
  }
}

// Execute deployment
if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = { main };

