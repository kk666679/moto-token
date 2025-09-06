// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MotoToken
 * @dev ERC-20 token with transaction fees, buyback mechanism, and reflection rewards
 * 
 * Features:
 * - 5% transaction fee (3% for liquidity, 2% for buyback)
 * - Reflection rewards in ETH
 * - Buyback and burn mechanism
 * - Integration with BaseSwap DEX
 */
contract MotoToken is Ownable, ERC20 {
    // BaseSwap Router address on Base network
    address public constant BASE_SWAP_ROUTER = 0x327Df1E6de05895d2ab08513aaDD9313Fe505d86;
    
    // Auxiliary contract addresses
    address public buybackContract;
    address public vaultContract;
    
    // Token configuration
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens
    uint256 public constant MAX_FEE_RATE = 10; // Maximum 10% fee
    
    // Fee rates (in percentage)
    uint256 public buybackRate = 2; // 2% fee for buybacks
    uint256 public liquidityRate = 3; // 3% fee for liquidity
    
    // Fee exemptions
    mapping(address => bool) public feeExempt;
    
    // Events
    event FeesDistributed(uint256 buybackAmount, uint256 liquidityAmount);
    event ContractsUpdated(address buyback, address vault);
    event FeeRatesUpdated(uint256 buybackRate, uint256 liquidityRate);
    event FeeExemptionUpdated(address account, bool exempt);
    
    /**
     * @dev Constructor initializes the token with name, symbol, and total supply
     * @param initialOwner The address that will own the contract
     */
    constructor(address initialOwner) ERC20("Moto", "MOTO") Ownable(initialOwner) {
        require(initialOwner != address(0), "MotoToken: invalid owner address");

        // Mint total supply to the initial owner
        _mint(msg.sender, 1000 * 10 ** decimals());

        // Set fee exemptions for owner and contract
        feeExempt[initialOwner] = true;
        feeExempt[address(this)] = true;
    }

    /**
     * @dev Sets the addresses of auxiliary contracts
     * @param _buyback Address of the Buyback contract
     * @param _vault Address of the AccumulatingVault contract
     */
    function setContracts(address _buyback, address _vault) external onlyOwner {
        require(_buyback != address(0), "MotoToken: invalid buyback address");
        require(_vault != address(0), "MotoToken: invalid vault address");
        
        buybackContract = _buyback;
        vaultContract = _vault;
        
        // Set fee exemptions for auxiliary contracts
        feeExempt[_buyback] = true;
        feeExempt[_vault] = true;
        
        emit ContractsUpdated(_buyback, _vault);
    }
    
    /**
     * @dev Updates fee rates (only owner)
     * @param _buybackRate New buyback fee rate
     * @param _liquidityRate New liquidity fee rate
     */
    function updateFeeRates(uint256 _buybackRate, uint256 _liquidityRate) external onlyOwner {
        require(_buybackRate + _liquidityRate <= MAX_FEE_RATE, "MotoToken: total fee exceeds maximum");
        
        buybackRate = _buybackRate;
        liquidityRate = _liquidityRate;
        
        emit FeeRatesUpdated(_buybackRate, _liquidityRate);
    }
    
    /**
     * @dev Sets fee exemption status for an address
     * @param account The address to update
     * @param exempt Whether the address should be exempt from fees
     */
    function setFeeExemption(address account, bool exempt) external onlyOwner {
        require(account != address(0), "MotoToken: invalid address");
        
        feeExempt[account] = exempt;
        emit FeeExemptionUpdated(account, exempt);
    }
    
    /**
     * @dev Override transfer function to implement fee mechanism
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _update(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "MotoToken: transfer amount must be greater than zero");
        
        // Check if fee should be applied
        bool takeFee = !feeExempt[from] && !feeExempt[to] && 
                      buybackContract != address(0) && vaultContract != address(0);
        
        if (takeFee && (buybackRate + liquidityRate) > 0) {
            uint256 totalFeeRate = buybackRate + liquidityRate;
            uint256 feeAmount = (amount * totalFeeRate) / 100;
            uint256 netAmount = amount - feeAmount;
            
            // Transfer fee to contract
            super._update(from, address(this), feeAmount);

            // Distribute fees to auxiliary contracts
            _distributeFees(feeAmount);

            // Transfer net amount to recipient
            super._update(from, to, netAmount);
        } else {
            // No fee, transfer full amount
            super._transfer(from, to, amount);
        }
    }
    
    /**
     * @dev Distributes collected fees to buyback and vault contracts
     * @param feeAmount Total fee amount to distribute
     */
    function _distributeFees(uint256 feeAmount) private {
        if (feeAmount == 0) return;
        
        uint256 totalRate = buybackRate + liquidityRate;
        uint256 buybackAmount = (feeAmount * buybackRate) / totalRate;
        uint256 liquidityAmount = feeAmount - buybackAmount;
        
        // Transfer to buyback contract
        if (buybackAmount > 0 && buybackContract != address(0)) {
            super._update(address(this), buybackContract, buybackAmount);
        }

        // Transfer to vault contract
        if (liquidityAmount > 0 && vaultContract != address(0)) {
            super._update(address(this), vaultContract, liquidityAmount);
        }
        
        emit FeesDistributed(buybackAmount, liquidityAmount);
    }
    
    /**
     * @dev Returns the total fee rate
     */
    function getTotalFeeRate() external view returns (uint256) {
        return buybackRate + liquidityRate;
    }
    
    /**
     * @dev Calculates fee amount for a given transfer amount
     * @param amount Transfer amount
     * @return feeAmount The fee that would be charged
     * @return netAmount The amount after fee deduction
     */
    function calculateFee(uint256 amount) external view returns (uint256 feeAmount, uint256 netAmount) {
        uint256 totalFeeRate = buybackRate + liquidityRate;
        feeAmount = (amount * totalFeeRate) / 100;
        netAmount = amount - feeAmount;
    }
    
    /**
     * @dev Emergency function to recover stuck tokens (only owner)
     * @param token Token address to recover
     * @param amount Amount to recover
     */
    function emergencyRecoverToken(address token, uint256 amount) external onlyOwner {
        require(token != address(this), "MotoToken: cannot recover MOTO tokens");
        IERC20(token).transfer(owner(), amount);
    }
    
    /**
     * @dev Emergency function to recover stuck ETH (only owner)
     */
    function emergencyRecoverETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

