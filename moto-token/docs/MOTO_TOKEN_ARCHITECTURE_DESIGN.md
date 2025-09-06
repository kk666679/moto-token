# Moto Token Architecture Design

# ![Moto Token Logo](https://qgmvsvq5fn67imzt.public.blob.vercel-storage.com/logo-bulat/%24moto.svg) Moto Token ($MOTO)

This document outlines the design of the Moto Token (`$MOTO`) and its auxiliary smart contracts, focusing on tokenomics, security, and compliance with Coinbase's asset listing requirements. The architecture is built on Coinbase's Base Layer 2 blockchain, leveraging its low-cost and high-throughput environment.

## 1. MotoToken Main Contract (`MotoToken.sol`)

The `MotoToken` contract will be an ERC-20 compliant token with additional functionalities to support transaction fees, liquidity provision, and interaction with buyback and reflection mechanisms. It will also implement the ERC-1363 standard for payable token functionality, allowing for more integrated interactions with other smart contracts.

### 1.1. Core Specifications
- **Token Name:** Moto
- **Symbol:** MOTO
- **Decimals:** 18
- **Total Supply:** 1,000,000,000 MOTO (1 Billion)
- **Blockchain:** Base (Coinbase's Ethereum L2)
- **Standards:** ERC-20, ERC-1363 (payable)
- **License:** MIT

### 1.2. Inheritance and Libraries
- `ERC20` from OpenZeppelin: Provides the basic ERC-20 functionalities.
- `Ownable` from OpenZeppelin: Enables ownership management, allowing the deployer to control critical functions (e.g., setting auxiliary contract addresses).
- `IERC1363` and `IERC1363Receiver` (custom implementation or from a library if available): To support the payable token standard.

### 1.3. State Variables
- `address public constant BASE_SWAP_ROUTER`: The address of the BaseSwap router (Uniswap V2 compatible) for liquidity operations and token swaps. (Value: `0x327Df1E6de05895d2ab08513aaDD9313Fe505d86`)
- `address public buybackContract`: Address of the `Buyback` contract.
- `address public vaultContract`: Address of the `AccumulatingVault` contract.
- `uint256 public constant TOTAL_SUPPLY`: Stores the total supply of 1 billion tokens with 18 decimals.
- `uint256 public buybackRate`: Percentage of transaction fee allocated to buybacks (2%).
- `uint256 public liquidityRate`: Percentage of transaction fee allocated to liquidity provision (3%).

### 1.4. Constructor
- Initializes the ERC-20 token with 


the given name and symbol, and mints the `TOTAL_SUPPLY` to the deployer.

### 1.5. Key Functions
- `setContracts(address _buyback, address _vault)`: An `onlyOwner` function to set the addresses of the `Buyback` and `AccumulatingVault` contracts after their deployment. This allows for a multi-contract deployment strategy.
- `_transfer(address from, address to, uint256 amount)`: This is the core function that will be overridden from the ERC-20 standard to implement the transaction fee mechanism. It will:
    - Bypass fees for transfers involving the owner or the contract itself (e.g., minting, internal operations).
    - Calculate a 5% fee on all other transfers (3% for liquidity, 2% for buyback).
    - Transfer the calculated fee to the `MotoToken` contract itself.
    - Call an internal `_distributeFees` function to handle the allocation of fees to the `buybackContract` and `vaultContract`.
    - Transfer the `netAmount` (original amount minus fee) to the recipient.
- `_distributeFees(uint256 fee)`: A private internal function responsible for:
    - Calculating the exact amounts for buyback (2/5 of the fee) and liquidity (3/5 of the fee).
    - Transferring the respective fee amounts from the `MotoToken` contract to the `buybackContract` and `vaultContract`.

## 2. Auxiliary Contracts

To manage the complex tokenomics, two auxiliary contracts will be developed:

### 2.1. Buyback Contract (`Buyback.sol`)

This contract will be responsible for executing the buyback and burn mechanism.

#### 2.1.1. Inheritance and Libraries
- No external inheritance beyond basic Solidity features.
- Will interact with `IUniswapV2Router02` interface for BaseSwap.

#### 2.1.2. State Variables
- `IUniswapV2Router02 public router`: Instance of the BaseSwap router interface, initialized with the `BASE_SWAP_ROUTER` address.
- `address public motoToken`: Address of the deployed `MotoToken` contract.
- `address public constant DEAD`: A constant address (`0x000000000000000000000000000000000000dEaD`) to which tokens will be sent for burning.

#### 2.1.3. Constructor
- Takes the `_moto` token address as an argument and initializes `motoToken`.

#### 2.1.4. Key Functions
- `buyAndBurn() external payable`: This function will be called by the `MotoToken` contract or an authorized external entity (e.g., a relayer or a timelock contract) when ETH fees are sent to it. It will:
    - Receive ETH as payment.
    - Swap the received ETH for `MotoToken` via the BaseSwap router, using `swapExactETHForTokens`.
    - The `to` address for the swap will be the `DEAD` address, effectively burning the bought `MotoToken`.
- `receive() external payable`: A fallback function to allow the contract to receive ETH.

### 2.2. AccumulatingVault Contract (`AccumulatingVault.sol`)

This contract will manage the reflection rewards distribution in ETH to holders, optimizing for gas costs.

#### 2.2.1. Inheritance and Libraries
- No external inheritance beyond basic Solidity features.

#### 2.2.2. State Variables
- `MotoToken public motoToken`: Instance of the `MotoToken` contract.
- `mapping(address => uint256) public rewards`: A mapping to store the accumulated ETH rewards for each holder.

#### 2.2.3. Constructor
- Takes the `_moto` token address as an argument and initializes `motoToken`.

#### 2.2.4. Key Functions
- `distribute() external payable`: This function will be called by the `MotoToken` contract when ETH fees for reflection are sent to it. It will:
    - Receive ETH as payment.
    - Implement logic to calculate and update the `rewards` mapping for all `MotoToken` holders proportionally to their `MotoToken` balance. This will likely involve iterating through token holders or using a more gas-efficient method like a checkpoint system (e.g., a Merkle tree or a snapshot-based distribution).
- `claimRewards() external`: Allows individual `MotoToken` holders to claim their accumulated ETH rewards. It will:
    - Transfer the `rewards[msg.sender]` amount to `msg.sender`.
    - Reset `rewards[msg.sender]` to 0 after claiming.

## 3. Liquidity Management

- **Initial Liquidity Lock:** 80% of initial liquidity will be locked for 1 year using a timelock contract. This provides assurance to investors against rug pulls. A separate `Timelock` contract will be used for this purpose.
- **Auto-Conversion of Fees:** The 3% liquidity fee collected by the `MotoToken` contract will be sent to the `AccumulatingVault` (or a dedicated liquidity management contract) and then used to automatically add liquidity to the MOTO/WETH pool on BaseSwap. This will involve converting the ETH portion of the fee to WETH (if necessary) and then calling the `addLiquidityETH` function on the BaseSwap router.

## 4. Security Considerations

- **Reentrancy Protection:** Implement reentrancy guards on functions that interact with external contracts (e.g., `_transfer`, `buyAndBurn`, `claimRewards`).
- **Access Control:** Use `onlyOwner` or similar modifiers for critical administrative functions.
- **Slippage Protection:** For the `buyAndBurn` function, implement minimum received token checks to prevent front-running and large slippage.
- **Gas Limits:** Ensure that iterative distribution mechanisms in `AccumulatingVault` are gas-efficient or use a pull-based system to avoid exceeding block gas limits.
- **External Audits:** Emphasize the necessity of professional security audits before mainnet deployment.

## 5. Compliance with Coinbase Asset Listing Requirements

- **Transparency:** All tokenomics, fee structures, and contract interactions will be clearly documented in a whitepaper and on the project website.
- **Liquidity:** Providing substantial initial liquidity on BaseSwap and locking a significant portion of it demonstrates commitment and stability.
- **Deflationary Mechanism:** The buyback and burn mechanism contributes to a healthy token ecosystem, which is generally viewed favorably.
- **Reflection Rewards:** The distribution of rewards in ETH adds value to holding the token and can attract a broader user base.
- **Open-Source:** All smart contracts will be open-source and verified on Basescan.
- **Community Engagement:** Active community building and transparent communication will be prioritized.

This architectural design aims to create a robust, secure, and sustainable DeFi token on the Base blockchain, aligning with the project's objectives and Coinbase's listing requirements.

