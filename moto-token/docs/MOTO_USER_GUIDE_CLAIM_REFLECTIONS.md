# 💰 How to Claim MOTO Reflections

## Overview
MOTO holders automatically earn ETH reflections based on their token balance. Here's how to claim your rewards:

## Method 1: Direct Contract Interaction

### Check Your Rewards
```javascript
// Connect to AccumulatingVault contract
const vault = new ethers.Contract(VAULT_ADDRESS, VAULT_ABI, signer);

// Check claimable amount
const [amount, nextClaimTime] = await vault.getUserRewardInfo(userAddress);
console.log("Claimable ETH:", ethers.formatEther(amount));
```

### Claim Rewards
```javascript
// Claim your ETH rewards
const tx = await vault.claimRewards();
await tx.wait();
```

## Method 2: Using Web Interface (Coming Soon)
- Visit the official Moto Token website
- Connect your wallet
- View your claimable rewards
- Click "Claim Rewards" button

## Important Information

### Claim Cooldown
- **Default**: 1 hour between claims
- **Purpose**: Prevents spam and reduces gas costs
- **Check**: Use `getUserRewardInfo()` to see next claim time

### Gas Considerations
- Claiming requires ETH for gas fees
- Batch multiple claims when possible
- Monitor Base network gas prices

### Reward Calculation
- Rewards are proportional to your MOTO balance
- Based on total ETH collected from fees
- Distributed among all eligible holders

## Troubleshooting

### "No rewards to claim"
- You may not have accumulated enough rewards yet
- Check if you've held tokens long enough
- Verify your token balance

### "Claim cooldown not met"
- Wait until the cooldown period expires
- Check `nextClaimTime` from `getUserRewardInfo()`

### Transaction Fails
- Ensure you have enough ETH for gas
- Check if you're connected to Base network
- Verify contract addresses are correct