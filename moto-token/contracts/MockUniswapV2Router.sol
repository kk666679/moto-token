// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MockUniswapV2Router
 * @dev Mock router for testing purposes
 */
contract MockUniswapV2Router {
    address public constant WETH = 0x4200000000000000000000000000000000000006; // Base WETH
    
    mapping(address => uint256) public tokenPrices; // Price in ETH per token
    
    constructor() {
        // Set default prices for testing
        tokenPrices[WETH] = 1 ether; // 1 WETH = 1 ETH
    }
    
    function setTokenPrice(address token, uint256 priceInETH) external {
        tokenPrices[token] = priceInETH;
    }
    
    function factory() external pure returns (address) {
        return address(0);
    }
    
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(path.length == 2, "Invalid path");
        require(path[1] == WETH, "Must swap to WETH");
        
        address tokenIn = path[0];
        uint256 price = tokenPrices[tokenIn];
        require(price > 0, "Price not set");
        
        uint256 ethOut = (amountIn * price) / 1 ether;
        require(ethOut >= amountOutMin, "Insufficient output amount");
        
        // Transfer tokens from sender
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        
        // Send ETH to recipient
        payable(to).transfer(ethOut);
        
        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = ethOut;
    }
    
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts) {
        require(path.length == 2, "Invalid path");
        require(path[0] == WETH, "Must swap from WETH");
        
        address tokenOut = path[1];
        uint256 price = tokenPrices[tokenOut];
        require(price > 0, "Price not set");
        
        uint256 tokensOut = (msg.value * 1 ether) / price;
        require(tokensOut >= amountOutMin, "Insufficient output amount");
        
        // Transfer tokens to recipient (assume this contract has tokens)
        IERC20(tokenOut).transfer(to, tokensOut);
        
        amounts = new uint[](2);
        amounts[0] = msg.value;
        amounts[1] = tokensOut;
    }
    
    function getAmountsOut(uint amountIn, address[] calldata path)
        external
        view
        returns (uint[] memory amounts)
    {
        require(path.length == 2, "Invalid path");
        
        amounts = new uint[](2);
        amounts[0] = amountIn;
        
        if (path[1] == WETH) {
            // Token to ETH
            uint256 price = tokenPrices[path[0]];
            amounts[1] = (amountIn * price) / 1 ether;
        } else if (path[0] == WETH) {
            // ETH to Token
            uint256 price = tokenPrices[path[1]];
            amounts[1] = (amountIn * 1 ether) / price;
        } else {
            revert("Unsupported path");
        }
    }
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        require(msg.value >= amountETHMin, "Insufficient ETH");
        require(amountTokenDesired >= amountTokenMin, "Insufficient token amount");
        
        // Transfer tokens from sender
        IERC20(token).transferFrom(msg.sender, address(this), amountTokenDesired);
        
        // Mock liquidity calculation
        amountToken = amountTokenDesired;
        amountETH = msg.value;
        liquidity = (amountToken * amountETH) / 1 ether; // Simple calculation
        
        // Mock LP token transfer (in real implementation, would mint LP tokens)
        // For testing, we just return the values
    }
    
    // Allow contract to receive ETH
    receive() external payable {}
}

