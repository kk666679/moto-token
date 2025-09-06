// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title LiquidityLocker
 * @dev Contract for locking liquidity tokens for a specified period
 * 
 * This contract locks LP tokens to provide assurance to investors
 * that liquidity cannot be removed (preventing rug pulls).
 */
contract LiquidityLocker is Ownable, ReentrancyGuard {
    struct LockInfo {
        address token;          // LP token address
        uint256 amount;         // Amount of tokens locked
        uint256 lockTime;       // When tokens were locked
        uint256 unlockTime;     // When tokens can be unlocked
        address beneficiary;    // Who can withdraw the tokens
        bool withdrawn;         // Whether tokens have been withdrawn
    }
    
    // Lock storage
    mapping(uint256 => LockInfo) public locks;
    mapping(address => uint256[]) public userLocks;
    uint256 public nextLockId = 1;
    
    // Minimum lock period (1 year)
    uint256 public constant MIN_LOCK_PERIOD = 365 days;
    
    // Events
    event TokensLocked(
        uint256 indexed lockId,
        address indexed token,
        address indexed beneficiary,
        uint256 amount,
        uint256 unlockTime
    );
    
    event TokensWithdrawn(
        uint256 indexed lockId,
        address indexed token,
        address indexed beneficiary,
        uint256 amount
    );
    
    event LockExtended(
        uint256 indexed lockId,
        uint256 newUnlockTime
    );
    
    /**
     * @dev Constructor
     * @param initialOwner Address of the initial owner
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        require(initialOwner != address(0), "LiquidityLocker: invalid owner address");
    }
    
    /**
     * @dev Locks tokens for a specified period
     * @param token Address of the token to lock
     * @param amount Amount of tokens to lock
     * @param lockPeriod Lock period in seconds (minimum 1 year)
     * @param beneficiary Address that can withdraw tokens after unlock
     * @return lockId The ID of the created lock
     */
    function lockTokens(
        address token,
        uint256 amount,
        uint256 lockPeriod,
        address beneficiary
    ) external nonReentrant returns (uint256 lockId) {
        require(token != address(0), "LiquidityLocker: invalid token address");
        require(amount > 0, "LiquidityLocker: amount must be greater than zero");
        require(lockPeriod >= MIN_LOCK_PERIOD, "LiquidityLocker: lock period too short");
        require(beneficiary != address(0), "LiquidityLocker: invalid beneficiary address");
        
        // Transfer tokens to this contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        // Create lock
        lockId = nextLockId++;
        uint256 unlockTime = block.timestamp + lockPeriod;
        
        locks[lockId] = LockInfo({
            token: token,
            amount: amount,
            lockTime: block.timestamp,
            unlockTime: unlockTime,
            beneficiary: beneficiary,
            withdrawn: false
        });
        
        userLocks[beneficiary].push(lockId);
        
        emit TokensLocked(lockId, token, beneficiary, amount, unlockTime);
    }
    
    /**
     * @dev Withdraws tokens after the lock period has expired
     * @param lockId ID of the lock to withdraw from
     */
    function withdrawTokens(uint256 lockId) external nonReentrant {
        LockInfo storage lock = locks[lockId];
        
        require(lock.amount > 0, "LiquidityLocker: lock does not exist");
        require(!lock.withdrawn, "LiquidityLocker: tokens already withdrawn");
        require(msg.sender == lock.beneficiary, "LiquidityLocker: not beneficiary");
        require(block.timestamp >= lock.unlockTime, "LiquidityLocker: tokens still locked");
        
        lock.withdrawn = true;
        
        // Transfer tokens to beneficiary
        IERC20(lock.token).transfer(lock.beneficiary, lock.amount);
        
        emit TokensWithdrawn(lockId, lock.token, lock.beneficiary, lock.amount);
    }
    
    /**
     * @dev Extends the lock period (can only increase, not decrease)
     * @param lockId ID of the lock to extend
     * @param newUnlockTime New unlock timestamp (must be later than current)
     */
    function extendLock(uint256 lockId, uint256 newUnlockTime) external {
        LockInfo storage lock = locks[lockId];
        
        require(lock.amount > 0, "LiquidityLocker: lock does not exist");
        require(!lock.withdrawn, "LiquidityLocker: tokens already withdrawn");
        require(msg.sender == lock.beneficiary, "LiquidityLocker: not beneficiary");
        require(newUnlockTime > lock.unlockTime, "LiquidityLocker: can only extend lock");
        
        lock.unlockTime = newUnlockTime;
        
        emit LockExtended(lockId, newUnlockTime);
    }
    
    /**
     * @dev Gets lock information
     * @param lockId ID of the lock
     * @return lock information
     */
    function getLockInfo(uint256 lockId) external view returns (LockInfo memory) {
        return locks[lockId];
    }
    
    /**
     * @dev Gets all lock IDs for a user
     * @param user User address
     * @return Array of lock IDs
     */
    function getUserLocks(address user) external view returns (uint256[] memory) {
        return userLocks[user];
    }
    
    /**
     * @dev Gets the number of locks for a user
     * @param user User address
     * @return Number of locks
     */
    function getUserLockCount(address user) external view returns (uint256) {
        return userLocks[user].length;
    }
    
    /**
     * @dev Checks if tokens can be withdrawn from a lock
     * @param lockId ID of the lock
     * @return canWithdraw Whether tokens can be withdrawn
     * @return timeRemaining Time remaining until unlock (0 if can withdraw)
     */
    function canWithdraw(uint256 lockId) external view returns (bool canWithdraw, uint256 timeRemaining) {
        LockInfo storage lock = locks[lockId];

        if (lock.amount == 0 || lock.withdrawn) {
            return (false, 0);
        }

        if (block.timestamp >= lock.unlockTime) {
            return (true, 0);
        } else {
            return (false, lock.unlockTime - block.timestamp);
        }
    }
    
    /**
     * @dev Gets total locked amount for a specific token
     * @param token Token address
     * @return totalLocked Total amount locked for the token
     */
    function getTotalLocked(address token) external view returns (uint256 totalLocked) {
        for (uint256 i = 1; i < nextLockId; i++) {
            LockInfo storage lock = locks[i];
            if (lock.token == token && !lock.withdrawn) {
                totalLocked += lock.amount;
            }
        }
    }
    
    /**
     * @dev Emergency function to recover accidentally sent tokens (only owner)
     * This can only recover tokens that are not part of any active lock
     * @param token Token address to recover
     * @param amount Amount to recover
     */
    function emergencyRecoverToken(address token, uint256 amount) external onlyOwner {
        uint256 totalLocked = this.getTotalLocked(token);
        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        
        require(contractBalance >= totalLocked + amount, "LiquidityLocker: cannot recover locked tokens");
        
        IERC20(token).transfer(owner(), amount);
    }
}

