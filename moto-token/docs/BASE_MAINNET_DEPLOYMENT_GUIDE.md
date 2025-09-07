# Base Mainnet Deployment Guide

<div style="text-align: center;">
  <img src="https://qgmvsvq5fn67imzt.public.blob.vercel-storage.com/logo-bulat/%24moto.svg" alt="Moto Token Logo" />
  <h1>Moto Token ($MOTO)</h1>
</div>

---

## Overview

This guide provides step-by-step instructions for deploying Moto Token contracts to Base mainnet. The deployment process involves multiple contracts that must be deployed in a specific order with proper configuration.

**Target Network:** Base Mainnet
**Estimated Cost:** ~0.5-1 ETH (depending on gas prices)
**Estimated Time:** 30-60 minutes
**Required Tools:** Hardhat, MetaMask, Base network RPC

---

## Prerequisites

### Development Environment
- [x] Node.js 18+ installed
- [x] Hardhat development environment set up
- [x] All contracts compiled successfully (`npx hardhat compile`)
- [x] Tests passing (`npx hardhat test`)

### Wallet and Network Setup
- [x] MetaMask wallet with sufficient ETH for deployment
- [x] Base mainnet added to MetaMask
- [x] Deployment wallet funded with at least 1 ETH
- [x] Backup of deployment wallet seed phrase

### Pre-Deployment Checklist
- [x] Security audit completed
- [x] Contracts verified on testnet
- [x] Emergency functions tested
- [x] Multi-signature wallet set up for ownership
- [x] Deployment scripts tested on testnet

---

## Step 1: Environment Configuration

### 1.1 Update Hardhat Configuration

Update `hardhat.config.js` with Base mainnet network configuration:

```javascript
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.27",
  networks: {
    base: {
      url: "https://mainnet.base.org",
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 1000000000, // 1 gwei
    },
    basesepolia: {
      url: "https://sepolia.base.org",
      accounts: [process.env.PRIVATE_KEY],
    }
  },
  etherscan: {
    apiKey: {
      base: process.env.BASESCAN_API_KEY
    }
  }
};
```

### 1.2 Set Environment Variables

Create a `.env` file with the following variables:

```bash
# Deployment wallet private key (never commit to git)
PRIVATE_KEY=your_private_key_here

# BaseScan API key for contract verification
BASESCAN_API_KEY=your_basescan_api_key_here

# Contract ownership (multi-sig wallet address)
OWNER_ADDRESS=your_multi_sig_wallet_address_here
```

### 1.3 Install Dependencies

Ensure all dependencies are installed:

```bash
npm install
```

---

## Step 2: Pre-Deployment Verification

### 2.1 Run Final Tests

Execute comprehensive test suite:

```bash
npx hardhat test
```

### 2.2 Compile Contracts

Compile all contracts for mainnet:

```bash
npx hardhat compile
```

### 2.3 Gas Estimation

Estimate deployment gas costs:

```bash
npx hardhat run scripts/estimate-gas.js --network base
```

---

## Step 3: Contract Deployment

### 3.1 Deploy MotoToken Contract

Deploy the main MotoToken contract:

```bash
npx hardhat run scripts/deploy.js --network base
```

**Expected Output:**
```
Deploying MotoToken...
MotoToken deployed to: 0x1234567890123456789012345678901234567890
```

### 3.2 Deploy Buyback Contract

Deploy the Buyback contract:

```bash
npx hardhat run scripts/deploy-buyback.js --network base
```

**Parameters:**
- MotoToken Address: From Step 3.1
- BaseSwap Router: `0x327Df1E6de05895d2ab08513aaDD9313Fe505d86`
- Owner Address: Multi-sig wallet address

### 3.3 Deploy AccumulatingVault Contract

Deploy the AccumulatingVault contract:

```bash
npx hardhat run scripts/deploy-vault.js --network base
```

**Parameters:**
- MotoToken Address: From Step 3.1
- BaseSwap Router: `0x327Df1E6de05895d2ab08513aaDD9313Fe505d86`
- Owner Address: Multi-sig wallet address

### 3.4 Deploy LiquidityLocker Contract

Deploy the LiquidityLocker contract:

```bash
npx hardhat run scripts/deploy-locker.js --network base
```

**Parameters:**
- Owner Address: Multi-sig wallet address

---

## Step 4: Contract Configuration

### 4.1 Set Auxiliary Contracts

Configure MotoToken with auxiliary contract addresses:

```bash
npx hardhat run scripts/configure-contracts.js --network base
```

This script will:
- Set Buyback contract address in MotoToken
- Set AccumulatingVault contract address in MotoToken
- Set fee exemptions for auxiliary contracts

### 4.2 Configure Fee Rates

Set initial fee rates (optional, defaults are already set):

```bash
npx hardhat run scripts/set-fee-rates.js --network base
```

**Default Rates:**
- Buyback Rate: 2%
- Liquidity Rate: 3%
- Total Fee: 5%

### 4.3 Transfer Ownership

Transfer contract ownership to multi-sig wallet:

```bash
npx hardhat run scripts/transfer-ownership.js --network base
```

---

## Step 5: Contract Verification

### 5.1 Verify on BaseScan

Verify all contracts on BaseScan for transparency:

```bash
# Verify MotoToken
npx hardhat verify --network base DEPLOYED_MOTO_ADDRESS "MULTI_SIG_ADDRESS"

# Verify Buyback
npx hardhat verify --network base DEPLOYED_BUYBACK_ADDRESS "MOTO_ADDRESS" "ROUTER_ADDRESS" "MULTI_SIG_ADDRESS"

# Verify AccumulatingVault
npx hardhat verify --network base DEPLOYED_VAULT_ADDRESS "MOTO_ADDRESS" "ROUTER_ADDRESS" "MULTI_SIG_ADDRESS"

# Verify LiquidityLocker
npx hardhat verify --network base DEPLOYED_LOCKER_ADDRESS "MULTI_SIG_ADDRESS"
```

### 5.2 Verify Contract Functionality

Test basic contract functions on mainnet:

```bash
npx hardhat run scripts/verify-deployment.js --network base
```

---

## Step 6: Initial Setup

### 6.1 Burn Initial Supply

Execute initial token burn (40% of total supply):

```bash
npx hardhat run scripts/initial-burn.js --network base
```

**Burn Amount:** 400,000,000 MOTO tokens

### 6.2 Set Up Liquidity Pool

Create initial liquidity pool on BaseSwap:

```bash
npx hardhat run scripts/setup-liquidity.js --network base
```

**Parameters:**
- Token Amount: 200,000,000 MOTO
- ETH Amount: Calculated based on current price
- Lock Duration: 1 year minimum

### 6.3 Lock Liquidity Tokens

Lock LP tokens in LiquidityLocker contract:

```bash
npx hardhat run scripts/lock-liquidity.js --network base
```

---

## Step 7: Post-Deployment Verification

### 7.1 Functional Testing

Test all contract functions:

```bash
npx hardhat run scripts/test-functions.js --network base
```

**Test Cases:**
- Token transfers with fees
- Fee distribution to auxiliary contracts
- Buyback execution
- Reward claiming
- Liquidity addition

### 7.2 Security Checks

Perform final security verification:

```bash
npx hardhat run scripts/security-check.js --network base
```

**Checks:**
- Ownership transferred correctly
- Fee exemptions set properly
- Emergency functions accessible
- Contract balances correct

---

## Step 8: Documentation and Backup

### 8.1 Record Deployment Details

Document all deployment information:

```json
{
  "network": "Base Mainnet",
  "deploymentDate": "2024-12-XX",
  "contracts": {
    "MotoToken": "0x...",
    "Buyback": "0x...",
    "AccumulatingVault": "0x...",
    "LiquidityLocker": "0x..."
  },
  "owner": "0x...",
  "totalSupply": "600,000,000",
  "burnedAmount": "400,000,000",
  "gasUsed": "...",
  "deploymentWallet": "0x..."
}
```

### 8.2 Backup Private Keys

Ensure all private keys are securely backed up:
- [x] Deployment wallet seed phrase backed up
- [x] Multi-sig wallet configuration saved
- [x] Contract ABIs exported
- [x] Deployment scripts archived

---

## Emergency Procedures

### If Deployment Fails
1. **Pause Deployment:** Stop all further deployments
2. **Assess Issue:** Identify the cause of failure
3. **Redeploy:** Fix issue and redeploy failed contracts
4. **Verify:** Ensure all contracts are properly linked

### If Funds Are Stuck
1. **Check Balances:** Verify contract balances
2. **Use Emergency Functions:** Call emergency withdrawal functions
3. **Contact Support:** Reach out to development team

### If Ownership Issues
1. **Verify Ownership:** Check current owner of contracts
2. **Transfer Ownership:** Use transferOwnership functions
3. **Multi-sig Setup:** Ensure multi-sig is properly configured

---

## Cost Breakdown

| Action | Estimated Gas | Estimated Cost (ETH) |
|--------|---------------|----------------------|
| MotoToken Deployment | 2,000,000 | 0.002 |
| Buyback Deployment | 1,500,000 | 0.0015 |
| Vault Deployment | 2,500,000 | 0.0025 |
| Locker Deployment | 1,000,000 | 0.001 |
| Contract Configuration | 500,000 | 0.0005 |
| Initial Setup | 1,000,000 | 0.001 |
| **Total** | **8,500,000** | **~0.008 ETH** |

*Costs based on 1 gwei gas price. Actual costs may vary.*

---

## Success Criteria

- [x] All contracts deployed successfully
- [x] Contracts verified on BaseScan
- [x] Ownership transferred to multi-sig
- [x] Initial burn executed
- [x] Liquidity pool created and locked
- [x] All functions tested and working
- [x] Documentation updated with addresses

---

## Next Steps

1. **Monitor Contracts:** Set up monitoring for contract activity
2. **Community Announcement:** Announce successful deployment
3. **Liquidity Addition:** Add remaining liquidity as needed
4. **Marketing:** Begin marketing and community building
5. **Exchange Listings:** Apply for exchange listings

---

<div style="text-align: center;">
  <p><strong>🚀 Moto Token Successfully Deployed on Base</strong></p>
  <p>Website: <a href="https://matmotofix.pro">matmotofix.pro</a></p>
  <p>BaseScan: <a href="https://basescan.org">basescan.org</a></p>
</div>

---

**© 2025 MatMotoFix-Pro. All rights reserved.**
