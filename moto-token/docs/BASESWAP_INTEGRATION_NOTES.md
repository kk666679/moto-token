# BaseSwap DEX Integration Notes

<div style="text-align: center;">
  <img src="https://qgmvsvq5fn67imzt.public.blob.vercel-storage.com/logo-bulat/%24moto.svg" alt="Moto Token Logo" />
  <h1>Moto Token ($MOTO)</h1>
</div>

BaseSwap is a decentralized exchange (DEX) built on Coinbase's Base Layer 2 network, functioning as an Automated Market Maker (AMM) similar to Uniswap V2.

**Key aspects for integration:**
- **Liquidity Pools:** BaseSwap utilizes liquidity pools where users deposit pairs of tokens (e.g., MOTO/WETH) in equal proportion to earn trading fees. This generates LP tokens representing their share of the pool.
- **Router Contract:** To interact with BaseSwap for operations like swapping tokens or adding/removing liquidity, a router contract is used. The provided `MotoToken` contract already includes a `BASE_SWAP_ROUTER` address: `0x327Df1E6de05895d2ab08513aaDD9313Fe505d86`.
- **Swapping:** The `Buyback` contract will need to interact with this router to swap ETH for MOTO tokens. This typically involves calling functions like `swapExactETHForTokens` on the router.
- **Adding Liquidity:** The `MotoToken` contract's fee distribution mechanism requires auto-adding 3% of fees to the MOTO/WETH liquidity pool. This will involve calling a function on the router (e.g., `addLiquidityETH`) to provide both MOTO and WETH to the pool and receive LP tokens.
- **LP Tokens:** When liquidity is provided, LP tokens are minted and sent to the provider. These LP tokens represent ownership of a portion of the liquidity pool.

**Confirmation of Router Address:**
I need to verify that the provided `BASE_SWAP_ROUTER` address (`0x327Df1E6de05895d2ab08513aaDD9313Fe505d86`) is indeed the correct Uniswap V2 Router02 address for BaseSwap on the Base network. I will use a block explorer like Basescan to confirm this.

**Interaction with Router:**
The `IUniswapV2Router02` interface will be used to interact with the BaseSwap router. The `swapExactETHForTokens` function is crucial for the buyback mechanism, and a similar function (e.g., `addLiquidityETH`) will be needed for the liquidity provision.

