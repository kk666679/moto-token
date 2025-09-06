# Moto Token User Guide: How to Claim ETH Reflections

<div style="text-align: center;"> <img src="https://qgmvsvq5fn67imzt.public.blob.vercel-storage.com/logo-bulat/%24moto.svg" alt="Moto Token Logo" width="150" /> <h1>The Moto Ecosystem</h1> <h2>A Self-Sustaining Economy on Base</h2> <p><strong>Powered by $MOTO</strong></p> </div>

---

## Overview

Moto Token automatically distributes 1.8% of all transaction fees as ETH reflections to holders. This guide will walk you through the process of claiming your accumulated ETH rewards.

**⏰ Claiming Frequency:** Rewards accumulate continuously
**💰 Claim Threshold:** Minimum 0.001 ETH
**⏳ Cooldown Period:** 1 hour between claims
**⚡ Network:** Base (Low-cost transactions)

---

## Prerequisites

### Wallet Requirements
- [x] **MetaMask** or compatible Web3 wallet
- [x] **Base network** added to your wallet
- [x] **$MOTO tokens** in your wallet
- [x] **Small amount of ETH** for gas fees

### Before You Start
1. **Backup your wallet** - Ensure you have your seed phrase secure
2. **Add Base network** to your wallet if not already configured
3. **Have some ETH** for transaction fees (very small amounts needed)

---

## Method 1: Web Interface (Recommended)

### Step 1: Access the Moto Token DApp
1. Visit the official Moto Token website: [mototoken.xyz](https://mototoken.xyz)
2. Click on **"Connect Wallet"** in the top right corner
3. Select your wallet (MetaMask recommended)
4. Approve the connection request

### Step 2: Navigate to Rewards Section
1. Look for the **"Rewards"** or **"Claim"** tab
2. Your current reward balance will be displayed
3. Check the **"Next Claim Time"** to see when you can claim again

### Step 3: Claim Your Rewards
1. Click the **"Claim Rewards"** button
2. Review the transaction details:
   - **Reward Amount:** ETH you'll receive
   - **Gas Fee:** Network transaction cost
   - **Net Benefit:** Rewards minus gas costs
3. Click **"Confirm"** to submit the transaction
4. Wait for confirmation (usually 5-30 seconds on Base)

### Step 4: Verify Receipt
1. Check your wallet balance for the ETH reward
2. Transaction will appear on [BaseScan](https://basescan.org)
3. Your claim cooldown will reset (1 hour)

---

## Method 2: Direct Contract Interaction

### Using BaseScan (Etherscan for Base)
1. Visit [BaseScan](https://basescan.org)
2. Search for the **AccumulatingVault contract** address
3. Click on the **"Contract"** tab
4. Click **"Write Contract"**
5. Connect your Web3 wallet

### Claim Function Parameters
```
Function: claimRewards()
Parameters: None required
Gas Limit: Auto (usually 100,000-200,000)
```

### Execute the Claim
1. Find the **"claimRewards"** function
2. Click **"Write"**
3. Confirm the transaction in your wallet
4. Wait for on-chain confirmation

---

## Method 3: Custom Script (Advanced Users)

### Using Web3.js
```javascript
const Web3 = require('web3');
const web3 = new Web3('https://mainnet.base.org');

const vaultContract = new web3.eth.Contract(VAULT_ABI, VAULT_ADDRESS);

async function claimRewards() {
  const accounts = await web3.eth.getAccounts();
  const gasPrice = await web3.eth.getGasPrice();

  const tx = await vaultContract.methods.claimRewards().send({
    from: accounts[0],
    gas: 200000,
    gasPrice: gasPrice
  });

  console.log('Claim transaction:', tx.transactionHash);
}
```

### Using Ethers.js
```javascript
const ethers = require('ethers');

const provider = new ethers.JsonRpcProvider('https://mainnet.base.org');
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
const vault = new ethers.Contract(VAULT_ADDRESS, VAULT_ABI, wallet);

async function claimRewards() {
  const tx = await vault.claimRewards();
  await tx.wait();
  console.log('Rewards claimed successfully!');
}
```

---

## Understanding Your Rewards

### How Rewards Are Calculated
```
Your Reward = (Your MOTO Balance / Total MOTO Supply) × Available ETH Rewards
```

### Real-Time Tracking
- **Live Balance:** Check your rewards anytime
- **Accumulation Rate:** Based on transaction volume
- **Claim Threshold:** Minimum 0.001 ETH required
- **Cooldown Timer:** 1-hour waiting period between claims

### Reward Statistics
- **Average Daily Rewards:** Varies with transaction volume
- **Optimal Claim Frequency:** When rewards exceed gas costs
- **Historical Claims:** Track all your past claims
- **Total Earned:** Cumulative ETH received

---

## Optimizing Your Rewards

### Timing Your Claims
- **High Volume Periods:** More transactions = more rewards
- **Low Gas Times:** Claim when Base network is less congested
- **Reward Threshold:** Wait until rewards justify gas costs
- **Regular Schedule:** Consider claiming weekly/monthly

### Maximizing Accumulation
- **Hold More Tokens:** Larger balance = proportionally more rewards
- **Long-term Holding:** Rewards compound over time
- **Active Ecosystem:** More transactions benefit all holders
- **Community Growth:** Expanding user base increases rewards

### Gas Fee Optimization
- **Base Network:** Lowest fees among major networks
- **Optimal Timing:** Claim during off-peak hours
- **Gas Price Monitoring:** Use tools to find best gas prices
- **Batch Claims:** Combine with other transactions

---

## Troubleshooting

### Common Issues

#### "Claim Not Available"
**Problem:** Trying to claim too soon after last claim
**Solution:** Wait for the 1-hour cooldown period to expire

#### "Insufficient Rewards"
**Problem:** Rewards below minimum threshold
**Solution:** Wait for more rewards to accumulate or hold more tokens

#### "Transaction Failed"
**Problem:** Network congestion or insufficient gas
**Solution:** Increase gas limit or try again during less busy times

#### "Wallet Not Connected"
**Problem:** Web3 wallet not properly connected
**Solution:** Refresh page and reconnect wallet

### Error Messages

#### "Cooldown Active"
```
Error: Claim cooldown is still active. Please wait 1 hour after your last claim.
Solution: Check the remaining cooldown time and try again later.
```

#### "Insufficient Balance"
```
Error: Reward balance too low to claim (minimum: 0.001 ETH)
Solution: Wait for more rewards to accumulate.
```

#### "Network Error"
```
Error: Failed to submit transaction to network
Solution: Check your internet connection and try again.
```

---

## Advanced Features

### Automatic Claiming
- **Bot Setup:** Use scripts for automated claiming
- **Smart Contracts:** Create contracts that claim for you
- **DApp Integration:** Third-party tools for auto-claiming
- **API Access:** Programmatic reward monitoring

### Reward Analytics
- **Portfolio Tracking:** Monitor all your rewards
- **Performance Metrics:** Track claiming efficiency
- **Historical Data:** Analyze past performance
- **Optimization Tools:** Find best claiming strategies

### Multi-Wallet Management
- **Portfolio View:** Track rewards across multiple wallets
- **Bulk Claims:** Claim from multiple addresses
- **Delegation:** Allow others to claim on your behalf
- **Security:** Enhanced protection for large holdings

---

## Security Best Practices

### Wallet Security
- **Hardware Wallets:** Use Ledger/Trezor for large holdings
- **Seed Phrase:** Keep backup secure and offline
- **Private Keys:** Never share or store insecurely
- **Regular Backups:** Backup wallet regularly

### Transaction Safety
- **Verify Addresses:** Always double-check contract addresses
- **Gas Limits:** Set appropriate gas limits for claims
- **Network Selection:** Ensure you're on Base mainnet
- **Amount Verification:** Confirm reward amounts before claiming

### Phishing Protection
- **Official Channels:** Only use official websites and contracts
- **URL Verification:** Check for correct domain names
- **Scam Awareness:** Be cautious of fake claiming services
- **Community Verification:** Confirm with community before using new tools

---

## Tax and Legal Considerations

### Tax Implications
- **Reportable Income:** ETH rewards may be taxable
- **Jurisdiction:** Check local tax laws
- **Record Keeping:** Maintain detailed transaction records
- **Professional Advice:** Consult tax professionals

### Legal Compliance
- **Local Laws:** Ensure compliance with local regulations
- **Platform Terms:** Agree to Moto Token terms of service
- **AML/KYC:** Some services may require identity verification
- **Responsible Use:** Use platform responsibly and ethically

---

## Frequently Asked Questions

### General Questions
**Q: How often should I claim rewards?**
A: It depends on gas costs vs. reward amounts. Many users claim weekly or when rewards reach 0.01 ETH.

**Q: What happens if I don't claim rewards?**
A: Rewards continue accumulating but you won't receive them until you claim.

**Q: Can I claim rewards for someone else?**
A: No, only the wallet owner can claim their own rewards.

### Technical Questions
**Q: Why is there a cooldown period?**
A: Prevents spam transactions and ensures fair distribution.

**Q: What if the network is congested?**
A: You may need to increase gas price or wait for network to clear.

**Q: Can I claim from multiple wallets?**
A: Yes, each wallet must claim separately.

### Reward Questions
**Q: How are rewards calculated?**
A: Proportional to your MOTO balance relative to total supply.

**Q: Why do rewards vary?**
A: Based on transaction volume and your holding percentage.

**Q: Are rewards guaranteed?**
A: Yes, if there are transactions, rewards will accumulate.

---

## Support and Resources

### Official Support
- **📧 Email:** support@mototoken.xyz
- **💬 Discord:** [discord.gg/mototoken](https://discord.gg/mototoken)
- **📖 Documentation:** [docs.mototoken.xyz](https://docs.mototoken.xyz)
- **🐦 Twitter:** [@MotoToken](https://twitter.com/MotoToken)

### Community Resources
- **📱 Telegram:** Community discussions and support
- **📺 YouTube:** Video tutorials and guides
- **📖 Medium:** Educational articles and updates
- **🔗 GitHub:** Open-source code and issues

### Tools and Utilities
- **BaseScan:** Transaction monitoring
- **DeFi Pulse:** Portfolio tracking
- **Zapper:** Multi-protocol dashboard
- **1inch:** Gas-optimized transactions

---

## Conclusion

Claiming ETH reflections from Moto Token is a straightforward process that rewards you for holding the token. By following this guide, you can:

- ✅ Understand the claiming mechanism
- ✅ Optimize your claiming strategy
- ✅ Troubleshoot common issues
- ✅ Maximize your passive income
- ✅ Stay secure while claiming

Remember to always claim responsibly and consider gas costs versus reward amounts for optimal results.

---

<div style="text-align: center;">
  <p><strong>🚀 Start Earning Passive Income Today</strong></p>
  <p>Hold $MOTO and claim your ETH reflections regularly!</p>
  <p>Website: <a href="https://mototoken.xyz">mototoken.xyz</a></p>
</div>

---

**© 2024 Moto Token. All rights reserved.**
