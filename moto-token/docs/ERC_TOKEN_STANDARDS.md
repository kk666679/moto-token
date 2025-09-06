# ERC-20 Token Standard

<div style="text-align: center;">
  <img src="https://qgmvsvq5fn67imzt.public.blob.vercel-storage.com/logo-bulat/%24moto.svg" alt="Moto Token Logo" />
  <h1>Moto Token ($MOTO)</h1>
</div>

ERC-20 is a technical standard used for issuing and implementing fungible tokens on the Ethereum blockchain. It defines a common set of rules and functions that all ERC-20 tokens must adhere to, ensuring interoperability between different token contracts and applications.

**Key features of ERC-20:**
- `totalSupply()`: Returns the total token supply.
- `balanceOf(address account)`: Returns the token balance of a given account.
- `transfer(address recipient, uint256 amount)`: Transfers tokens from the caller's address to a recipient.
- `allowance(address owner, address spender)`: Returns the amount of tokens that an owner has allowed a spender to withdraw.
- `approve(address spender, uint256 amount)`: Allows a spender to withdraw a specified amount of tokens from the caller's account.
- `transferFrom(address sender, address recipient, uint256 amount)`: Transfers tokens from a sender's account to a recipient's account using the allowance mechanism.

**Events:**
- `Transfer(address indexed from, address indexed to, uint256 value)`: Emitted when tokens are transferred.
- `Approval(address indexed owner, address indexed spender, uint256 value)`: Emitted when an allowance is set.

# ERC-1363: Payable Token Standard

ERC-1363 is an extension interface for ERC-20 tokens that adds the capability to execute custom logic on a recipient contract after transfers, or on a spender contract after approvals. This standard aims to make token payments easier and more integrated with smart contract interactions, eliminating the need for separate approval transactions in many cases.

**Key features of ERC-1363:**
- Extends ERC-20 functionality.
- Allows for `transferAndCall` and `transferFromAndCall` functions, which trigger a callback function on the recipient contract after a token transfer.
- Allows for `approveAndCall` function, which triggers a callback function on the spender contract after an approval.

**Benefits of ERC-1363:**
- **Improved User Experience:** Simplifies interactions by combining token transfer/approval and function execution into a single transaction.
- **Enhanced Security:** Can improve security by allowing recipient contracts to validate incoming transfers and reject malicious ones.
- **Atomic Operations:** Ensures that token transfer and subsequent logic execution are atomic, meaning either both succeed or both fail.

