// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Buyback
 * @dev Contract responsible for buying back MOTO tokens and burning them
 * 
 * This contract receives MOTO tokens from the main contract as fees,
 * swaps them for ETH via BaseSwap, and then uses that ETH to buy back
 * more MOTO tokens which are sent to a burn address.
 */
contract Buyback is Ownable, ReentrancyGuard {
    // BaseSwap Router interface
    IUniswapV2Router02 public immutable router;
    
    // MOTO token contract
    IERC20 public immutable motoToken;
    
    // Burn address (dead address)
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    
    // Minimum token amount to trigger buyback
    uint256 public minTokensForBuyback = 1000 * 10**18; // 1000 MOTO
    
    // Slippage protection (in basis points, 500 = 5%)
    uint256 public maxSlippage = 500;
    
    // Events
    event BuybackExecuted(uint256 tokensSwappedForETH, uint256 ethReceived, uint256 tokensBought, uint256 tokensBurned);
    event MinTokensUpdated(uint256 newMinTokens);
    event MaxSlippageUpdated(uint256 newMaxSlippage);
    event EmergencyWithdraw(address token, uint256 amount);
    
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
        require(_motoToken != address(0), "Buyback: invalid MOTO token address");
        require(_router != address(0), "Buyback: invalid router address");
        require(initialOwner != address(0), "Buyback: invalid owner address");
        
        motoToken = IERC20(_motoToken);
        router = IUniswapV2Router02(_router);
    }
    
    /**
     * @dev Updates minimum tokens required for buyback
     * @param _minTokens New minimum token amount
     */
    function updateMinTokensForBuyback(uint256 _minTokens) external onlyOwner {
        minTokensForBuyback = _minTokens;
        emit MinTokensUpdated(_minTokens);
    }
    
    /**
     * @dev Updates maximum slippage tolerance
     * @param _maxSlippage New maximum slippage in basis points
     */
    function updateMaxSlippage(uint256 _maxSlippage) external onlyOwner {
        require(_maxSlippage <= 2000, "Buyback: slippage too high"); // Max 20%
        maxSlippage = _maxSlippage;
        emit MaxSlippageUpdated(_maxSlippage);
    }
    
    /**
     * @dev Executes buyback and burn process
     * Can be called by anyone when conditions are met
     */
    function executeBuyback() external nonReentrant {
        uint256 tokenBalance = motoToken.balanceOf(address(this));
        require(tokenBalance >= minTokensForBuyback, "Buyback: insufficient tokens for buyback");
        
        // Step 1: Swap MOTO tokens for ETH
        uint256 ethReceived = _swapTokensForETH(tokenBalance);
        require(ethReceived > 0, "Buyback: no ETH received from swap");
        
        // Step 2: Use ETH to buy MOTO tokens and send to burn address
        uint256 tokensBought = _buyTokensAndBurn(ethReceived);
        
        emit BuybackExecuted(tokenBalance, ethReceived, tokensBought, tokensBought);
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
     * @dev Buys MOTO tokens with ETH and sends them to burn address
     * @param ethAmount Amount of ETH to use for buying
     * @return tokensBought Amount of tokens bought and burned
     */
    function _buyTokensAndBurn(uint256 ethAmount) private returns (uint256 tokensBought) {
        // Set up swap path: WETH -> MOTO
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(motoToken);
        
        // Calculate minimum tokens out with slippage protection
        uint256[] memory amountsOut = router.getAmountsOut(ethAmount, path);
        uint256 minTokensOut = (amountsOut[1] * (10000 - maxSlippage)) / 10000;
        
        // Execute swap - tokens go directly to burn address
        uint256[] memory amounts = router.swapExactETHForTokens{value: ethAmount}(
            minTokensOut,
            path,
            DEAD, // Send tokens directly to burn address
            block.timestamp + 300 // 5 minute deadline
        );
        
        tokensBought = amounts[1];
    }
    
    /**
     * @dev Checks if buyback can be executed
     * @return canExecute Whether buyback can be executed
     * @return tokenBalance Current token balance
     */
    function canExecuteBuyback() external view returns (bool canExecute, uint256 tokenBalance) {
        tokenBalance = motoToken.balanceOf(address(this));
        canExecute = tokenBalance >= minTokensForBuyback;
    }
    
    /**
     * @dev Gets expected ETH amount for current token balance
     * @return expectedETH Expected ETH amount from swapping current tokens
     */
    function getExpectedETHFromTokens() external view returns (uint256 expectedETH) {
        uint256 tokenBalance = motoToken.balanceOf(address(this));
        if (tokenBalance == 0) return 0;
        
        address[] memory path = new address[](2);
        path[0] = address(motoToken);
        path[1] = router.WETH();
        
        try router.getAmountsOut(tokenBalance, path) returns (uint256[] memory amounts) {
            expectedETH = amounts[1];
        } catch {
            expectedETH = 0;
        }
    }
    
    /**
     * @dev Emergency function to withdraw tokens (only owner)
     * @param token Token address to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdrawToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
        emit EmergencyWithdraw(token, amount);
    }
    
    /**
     * @dev Emergency function to withdraw ETH (only owner)
     */
    function emergencyWithdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit EmergencyWithdraw(address(0), balance);
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

