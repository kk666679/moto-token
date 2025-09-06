// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AccumulatingVault
 * @dev Contract for managing reflection rewards and liquidity provision
 * 
 * This contract receives MOTO tokens from the main contract as fees,
 * converts them to ETH, and manages both reflection rewards distribution
 * and automatic liquidity provision to the MOTO/ETH pool.
 */
contract AccumulatingVault is Ownable, ReentrancyGuard {
    // BaseSwap Router interface
    IUniswapV2Router02 public immutable router;
    
    // MOTO token contract
    IERC20 public immutable motoToken;
    
    // Reward distribution tracking
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastClaimTime;
    
    // Total rewards distributed
    uint256 public totalRewardsDistributed;
    uint256 public totalETHForRewards;
    uint256 public totalETHForLiquidity;
    
    // Distribution settings
    uint256 public rewardPercentage = 60; // 60% of converted ETH goes to rewards
    uint256 public liquidityPercentage = 40; // 40% goes to liquidity
    
    // Minimum amounts for operations
    uint256 public minTokensForConversion = 500 * 10**18; // 500 MOTO
    uint256 public minETHForLiquidity = 0.01 ether; // 0.01 ETH
    
    // Slippage protection
    uint256 public maxSlippage = 500; // 5% in basis points
    
    // Claim cooldown (to prevent spam)
    uint256 public claimCooldown = 1 hours;
    
    // Events
    event TokensConverted(uint256 tokensConverted, uint256 ethReceived);
    event RewardsDistributed(uint256 totalHolders, uint256 totalETH);
    event RewardsClaimed(address indexed user, uint256 amount);
    event LiquidityAdded(uint256 tokenAmount, uint256 ethAmount, uint256 liquidity);
    event PercentagesUpdated(uint256 rewardPercentage, uint256 liquidityPercentage);
    event MinAmountsUpdated(uint256 minTokens, uint256 minETH);
    
    /**
     * @dev Constructor
     * @param _motoToken Address of the MOTO token contract
     * @param _router Address of the BaseSwap router
     * @param initialOwner Address of the initial owner
     */
    constructor(
        address _motoToken,
        address _router,
        address initialOwner
    ) Ownable(initialOwner) {
        require(_motoToken != address(0), "AccumulatingVault: invalid MOTO token address");
        require(_router != address(0), "AccumulatingVault: invalid router address");
        require(initialOwner != address(0), "AccumulatingVault: invalid owner address");
        
        motoToken = IERC20(_motoToken);
        router = IUniswapV2Router02(_router);
    }
    
    /**
     * @dev Updates the distribution percentages
     * @param _rewardPercentage Percentage for rewards (0-100)
     * @param _liquidityPercentage Percentage for liquidity (0-100)
     */
    function updatePercentages(uint256 _rewardPercentage, uint256 _liquidityPercentage) external onlyOwner {
        require(_rewardPercentage + _liquidityPercentage == 100, "AccumulatingVault: percentages must sum to 100");
        
        rewardPercentage = _rewardPercentage;
        liquidityPercentage = _liquidityPercentage;
        
        emit PercentagesUpdated(_rewardPercentage, _liquidityPercentage);
    }
    
    /**
     * @dev Updates minimum amounts for operations
     * @param _minTokens Minimum tokens for conversion
     * @param _minETH Minimum ETH for liquidity addition
     */
    function updateMinAmounts(uint256 _minTokens, uint256 _minETH) external onlyOwner {
        minTokensForConversion = _minTokens;
        minETHForLiquidity = _minETH;
        
        emit MinAmountsUpdated(_minTokens, _minETH);
    }
    
    /**
     * @dev Updates maximum slippage tolerance
     * @param _maxSlippage New maximum slippage in basis points
     */
    function updateMaxSlippage(uint256 _maxSlippage) external onlyOwner {
        require(_maxSlippage <= 2000, "AccumulatingVault: slippage too high"); // Max 20%
        maxSlippage = _maxSlippage;
    }
    
    /**
     * @dev Updates claim cooldown period
     * @param _cooldown New cooldown period in seconds
     */
    function updateClaimCooldown(uint256 _cooldown) external onlyOwner {
        require(_cooldown <= 24 hours, "AccumulatingVault: cooldown too long");
        claimCooldown = _cooldown;
    }
    
    /**
     * @dev Converts MOTO tokens to ETH and distributes for rewards and liquidity
     * Can be called by anyone when conditions are met
     */
    function processTokens() external nonReentrant {
        uint256 tokenBalance = motoToken.balanceOf(address(this));
        require(tokenBalance >= minTokensForConversion, "AccumulatingVault: insufficient tokens");
        
        // Convert tokens to ETH
        uint256 ethReceived = _swapTokensForETH(tokenBalance);
        require(ethReceived > 0, "AccumulatingVault: no ETH received");
        
        // Distribute ETH between rewards and liquidity
        uint256 ethForRewards = (ethReceived * rewardPercentage) / 100;
        uint256 ethForLiquidity = ethReceived - ethForRewards;
        
        totalETHForRewards += ethForRewards;
        totalETHForLiquidity += ethForLiquidity;
        
        emit TokensConverted(tokenBalance, ethReceived);
        
        // Add liquidity if we have enough ETH
        if (ethForLiquidity >= minETHForLiquidity) {
            _addLiquidity(ethForLiquidity);
        }
    }
    
    /**
     * @dev Distributes rewards to a batch of holders
     * @param holders Array of holder addresses
     */
    function distributeRewards(address[] calldata holders) external nonReentrant {
        require(totalETHForRewards > 0, "AccumulatingVault: no ETH available for rewards");
        require(holders.length > 0, "AccumulatingVault: no holders provided");
        require(holders.length <= 100, "AccumulatingVault: too many holders in batch");
        
        uint256 totalSupply = motoToken.totalSupply();
        uint256 ethToDistribute = totalETHForRewards;
        uint256 totalDistributed = 0;
        
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            uint256 balance = motoToken.balanceOf(holder);
            
            if (balance > 0) {
                uint256 reward = (ethToDistribute * balance) / totalSupply;
                if (reward > 0) {
                    rewards[holder] += reward;
                    totalDistributed += reward;
                }
            }
        }
        
        totalETHForRewards -= totalDistributed;
        totalRewardsDistributed += totalDistributed;
        
        emit RewardsDistributed(holders.length, totalDistributed);
    }
    
    /**
     * @dev Allows users to claim their accumulated rewards
     */
    function claimRewards() external nonReentrant {
        address user = msg.sender;
        require(rewards[user] > 0, "AccumulatingVault: no rewards to claim");
        require(
            block.timestamp >= lastClaimTime[user] + claimCooldown,
            "AccumulatingVault: claim cooldown not met"
        );
        
        uint256 reward = rewards[user];
        rewards[user] = 0;
        lastClaimTime[user] = block.timestamp;
        
        // Transfer ETH reward to user
        (bool success, ) = payable(user).call{value: reward}("");
        require(success, "AccumulatingVault: ETH transfer failed");
        
        emit RewardsClaimed(user, reward);
    }
    
    /**
     * @dev Swaps MOTO tokens for ETH
     * @param tokenAmount Amount of tokens to swap
     * @return ethReceived Amount of ETH received
     */
    function _swapTokensForETH(uint256 tokenAmount) private returns (uint256 ethReceived) {
        // Approve router to spend tokens
        motoToken.approve(address(router), tokenAmount);
        
        // Set up swap path: MOTO -> WETH
        address[] memory path = new address[](2);
        path[0] = address(motoToken);
        path[1] = router.WETH();
        
        // Calculate minimum ETH out with slippage protection
        uint256[] memory amountsOut = router.getAmountsOut(tokenAmount, path);
        uint256 minETHOut = (amountsOut[1] * (10000 - maxSlippage)) / 10000;
        
        // Record ETH balance before swap
        uint256 ethBefore = address(this).balance;
        
        // Execute swap
        router.swapExactTokensForETH(
            tokenAmount,
            minETHOut,
            path,
            address(this),
            block.timestamp + 300 // 5 minute deadline
        );
        
        // Calculate ETH received
        ethReceived = address(this).balance - ethBefore;
    }
    
    /**
     * @dev Adds liquidity to the MOTO/ETH pool
     * @param ethAmount Amount of ETH to use for liquidity
     */
    function _addLiquidity(uint256 ethAmount) private {
        // Calculate how many tokens we need for the ETH amount
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(motoToken);
        
        uint256[] memory amountsOut = router.getAmountsOut(ethAmount / 2, path);
        uint256 tokensNeeded = amountsOut[1];
        
        // Buy tokens with half the ETH
        uint256 minTokensOut = (tokensNeeded * (10000 - maxSlippage)) / 10000;
        
        uint256[] memory amounts = router.swapExactETHForTokens{value: ethAmount / 2}(
            minTokensOut,
            path,
            address(this),
            block.timestamp + 300
        );
        
        uint256 tokensBought = amounts[1];
        uint256 ethForLiquidity = ethAmount / 2;
        
        // Approve router to spend tokens
        motoToken.approve(address(router), tokensBought);
        
        // Add liquidity
        (uint256 tokenAmount, uint256 ethUsed, uint256 liquidity) = router.addLiquidityETH{value: ethForLiquidity}(
            address(motoToken),
            tokensBought,
            (tokensBought * (10000 - maxSlippage)) / 10000, // Min tokens
            (ethForLiquidity * (10000 - maxSlippage)) / 10000, // Min ETH
            owner(), // LP tokens go to owner
            block.timestamp + 300
        );
        
        emit LiquidityAdded(tokenAmount, ethUsed, liquidity);
    }
    
    /**
     * @dev Gets user's claimable rewards and next claim time
     * @param user User address
     * @return claimableAmount Amount user can claim
     * @return nextClaimTime When user can claim next
     */
    function getUserRewardInfo(address user) external view returns (uint256 claimableAmount, uint256 nextClaimTime) {
        claimableAmount = rewards[user];
        nextClaimTime = lastClaimTime[user] + claimCooldown;
        if (nextClaimTime < block.timestamp) {
            nextClaimTime = block.timestamp;
        }
    }
    
    /**
     * @dev Checks if token processing can be executed
     * @return canProcess Whether processing can be executed
     * @return tokenBalance Current token balance
     */
    function canProcessTokens() external view returns (bool canProcess, uint256 tokenBalance) {
        tokenBalance = motoToken.balanceOf(address(this));
        canProcess = tokenBalance >= minTokensForConversion;
    }
    
    /**
     * @dev Emergency function to withdraw tokens (only owner)
     * @param token Token address to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdrawToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }
    
    /**
     * @dev Emergency function to withdraw ETH (only owner)
     */
    function emergencyWithdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {}
    
    /**
     * @dev Fallback function
     */
    fallback() external payable {}
}

