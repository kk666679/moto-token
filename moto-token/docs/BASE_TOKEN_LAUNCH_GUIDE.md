# Launch a Token

<div style="text-align: center;">
  <img src="https://qgmvsvq5fn67imzt.public.blob.vercel-storage.com/logo-bulat/%24moto.svg" alt="Moto Token Logo" />
  <h1>Moto Token ($MOTO)</h1>
</div>

Launching a token on Base can be accomplished through multiple approaches, from no-code platforms to custom smart contract development. This guide helps you choose the right method and provides implementation details for both approaches.

**For most users:** Use existing token launch platforms like Zora, Clanker, or Flaunch. These tools handle the technical complexity while providing unique features for different use cases.**For developers:** Build custom ERC-20 tokens using Foundry and OpenZeppelin’s battle-tested contracts for maximum control and customization.

## Choosing Your Launch Approach

### Platform-Based Launch (Recommended for Most Users)

Choose a platform when you want:

*   Quick deployment without coding
*   Built-in community features
*   Automated liquidity management
*   Social integration capabilities

### Custom Development (For Developers)

Build your own smart contract when you need:

*   Custom tokenomics or functionality
*   Full control over contract behavior
*   Integration with existing systems
*   Advanced security requirements

## Token Launch Platforms on Base

### Zora

**Best for:** Content creators and social tokens Zora transforms every post into a tradeable ERC-20 token with automatic Uniswap integration. Each post becomes a “coin” with 1 billion supply, creators receive 10 million tokens, and earn 1% of all trading fees. **Key Features:**

*   Social-first token creation
*   Automatic liquidity pools
*   Revenue sharing for creators
*   Built-in trading interface

[Get started with Zora →]()

### Clanker

**Best for:** Quick memecoin launches via social media Clanker is an AI-driven token deployment tool that operates through Farcaster. Users can create ERC-20 tokens on Base by simply tagging @clanker with their token concept. **Key Features:**

*   AI-powered automation
*   Social media integration via Farcaster
*   Instant deployment
*   Community-driven discovery

[Get started with Clanker →]() or visit [clanker.world]()

### Flaunch

**Best for:** Advanced memecoin projects with sophisticated tokenomics Flaunch leverages Uniswap V4 to enable programmable revenue splits, automated buybacks, and Progressive Bid Walls for price support. Creators can customize fee distributions and treasury management. **Key Features:**

*   Programmable revenue sharing
*   Automated buyback mechanisms
*   Progressive Bid Wall technology
*   Treasury management tools

[Get started with Flaunch →]()

## Technical Implementation with Foundry

For developers who want full control over their token implementation, here’s how to create and deploy a custom ERC-20 token on Base using Foundry.

Before launching a custom developed token to production, always conduct security reviews by expert smart contract developers.

### Prerequisites

1

Install Foundry

Install Foundry on your system:

Terminal

    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    

For detailed installation instructions, see the [Foundry documentation]().

2

Get Test ETH

Obtain Base Sepolia ETH for testing from the [Base Faucet]()

3

Set Up Development Environment

Configure your wallet and development tools for Base testnet deployment

### Project Setup

Initialize a new Foundry project and clean up template files:

Terminal

    # Create new project
    forge init my-token-project
    cd my-token-project
    
    # Remove template files we don't need
    rm src/Counter.sol script/Counter.s.sol test/Counter.t.sol
    

Install OpenZeppelin contracts for secure, audited ERC-20 implementation:

Terminal

    # Install OpenZeppelin contracts library
    forge install OpenZeppelin/openzeppelin-contracts
    

### Smart Contract Development

Create your token contract using OpenZeppelin’s ERC-20 implementation:

src/MyToken.sol

    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.19;
    
    import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    
    /**
     * @title MyToken
     * @dev ERC-20 token with minting capabilities and supply cap
     */
    contract MyToken is ERC20, Ownable {
        // Maximum number of tokens that can ever exist
        uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens
        
        constructor(
            string memory name,
            string memory symbol,
            uint256 initialSupply,
            address initialOwner
        ) ERC20(name, symbol) Ownable(initialOwner) {
            require(initialSupply <= MAX_SUPPLY, "Initial supply exceeds max supply");
            // Mint initial supply to the contract deployer
            _mint(initialOwner, initialSupply);
        }
        
        /**
         * @dev Mint new tokens (only contract owner can call this)
         * @param to Address to mint tokens to
         * @param amount Amount of tokens to mint
         */
        function mint(address to, uint256 amount) public onlyOwner {
            require(totalSupply() + amount <= MAX_SUPPLY, "Minting would exceed max supply");
            _mint(to, amount);
        }
        
        /**
         * @dev Burn tokens from caller's balance
         * @param amount Amount of tokens to burn
         */
        function burn(uint256 amount) public {
            _burn(msg.sender, amount);
        }
    }
    

### Deployment Script

Create a deployment script following Foundry best practices:

script/DeployToken.s.sol

    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.19;
    
    import {Script, console} from "forge-std/Script.sol";
    import {MyToken} from "../src/MyToken.sol";
    
    contract DeployToken is Script {
        function run() external {
            // Load deployer's private key from environment variables
            uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
            address deployerAddress = vm.addr(deployerPrivateKey);
            
            // Token configuration parameters
            string memory name = "My Token";
            string memory symbol = "MTK";
            uint256 initialSupply = 100_000_000 * 10**18; // 100 million tokens
            
            // Start broadcasting transactions
            vm.startBroadcast(deployerPrivateKey);
            
            // Deploy the token contract
            MyToken token = new MyToken(
                name,
                symbol,
                initialSupply,
                deployerAddress
            );
            
            // Stop broadcasting transactions
            vm.stopBroadcast();
            
            // Log deployment information
            console.log("Token deployed to:", address(token));
            console.log("Token name:", token.name());
            console.log("Token symbol:", token.symbol());
            console.log("Initial supply:", token.totalSupply());
            console.log("Deployer balance:", token.balanceOf(deployerAddress));
        }
    }
    

### Environment Configuration

Create a `.env` file with your configuration:

.env

    PRIVATE_KEY=your_private_key_here
    BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
    BASE_MAINNET_RPC_URL=https://mainnet.base.org
    BASESCAN_API_KEY=your_basescan_api_key_here
    

Update `foundry.toml` for Base network configuration:

foundry.toml

    [profile.default]
    src = "src"
    out = "out"
    libs = ["lib"]
    remappings = ["@openzeppelin/=lib/openzeppelin-contracts/"]
    
    [rpc_endpoints]
    base_sepolia = "${BASE_SEPOLIA_RPC_URL}"
    base_mainnet = "${BASE_MAINNET_RPC_URL}"
    
    [etherscan]
    base_sepolia = { key = "${BASESCAN_API_KEY}", url = "https://api-sepolia.basescan.org/api" }
    base = { key = "${BASESCAN_API_KEY}", url = "https://api.basescan.org/api" }
    

### Testing

Create comprehensive tests for your token:

test/MyToken.t.sol

    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.19;
    
    import {Test, console} from "forge-std/Test.sol";
    import {MyToken} from "../src/MyToken.sol";
    
    contract MyTokenTest is Test {
        MyToken public token;
        address public owner = address(0x123);
        address public user = address(0x456);
        
        function setUp() public {
            // Deploy the token contract before each test
            token = new MyToken("My Token", "MTK", 100e18, owner);
        }
        
        function test_InitialSupply() public {
            assertEq(token.totalSupply(), 100e18);
            assertEq(token.balanceOf(owner), 100e18);
        }
        
        function test_Mint() public {
            vm.prank(owner);
            token.mint(user, 50e18);
            assertEq(token.balanceOf(user), 50e18);
        }
        
        function test_Burn() public {
            vm.prank(owner);
            token.transfer(user, 20e18);
            
            vm.prank(user);
            token.burn(10e18);
            
            assertEq(token.balanceOf(user), 10e18);
        }
        
        function test_Transfer() public {
            vm.prank(owner);
            token.transfer(user, 30e18);
            assertEq(token.balanceOf(owner), 70e18);
            assertEq(token.balanceOf(user), 30e18);
        }
        
        function test_Fail_MintExceedsMaxSupply() public {
            vm.prank(owner);
            // Try to mint more than the max supply
            token.mint(user, 1_000_000_001 * 10**18);
        }
    }
    

### Deployment

Deploy your token to Base Sepolia testnet:

Terminal

    # Ensure your .env file is populated
    source .env
    
    # Deploy to Base Sepolia
    forge script script/DeployToken.s.sol:DeployToken --rpc-url base_sepolia --broadcast --verify -vvvv
    

After successful deployment, your token will be live on Base Sepolia and verified on Basescan.

## Post-Launch Best Practices

### Security

*   **Audit:** Before mainnet deployment, get a full security audit from a reputable firm.
*   **Timelocks:** Lock liquidity and team tokens using a timelock contract to build trust.
*   **Multisig:** Use a multisig wallet for ownership control to prevent single points of failure.

### Community

*   **Transparency:** Clearly communicate your tokenomics, distribution, and goals.
*   **Engagement:** Build a strong community through social media, forums, and events.
*   **Governance:** Consider using tools like Snapshot for community-led governance.

### Liquidity

*   **Provide Liquidity:** Add liquidity to a decentralized exchange like Uniswap to enable trading.
*   **Incentivize:** Offer rewards for liquidity providers to ensure a healthy market.

Was this page helpful?

YesNo

