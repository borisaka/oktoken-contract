# Project Name: OkToken
## Description

This ERC-4626 token implementation features unique deposit and withdrawal fee mechanisms, with OpenZeppelin libraries ensuring standard functionalities for security and efficiency. The contract employs advanced features like EIP712 for structured data signing and ERC20Permit for gasless transactions.

## Key Features

- **ERC-4626 Standard**: Tokenized vaults standard with interest-bearing capability.
- **OpenZeppelin Libraries**: Ensures robust and secure contract functionalities.
- **ERC20Permit Extension**: Gasless transactions via off-chain signatures.
- **EIP712 Implementation**: Secure and user-friendly structured data signing.
- **Fee Mechanism**: Fees on deposits and withdrawals with 70% retention in the contract. 30% of the fees transferred to the owner.
- **Advanced Math Operations**: Custom libraries for extended mathematical capabilities.

## Technologies

- Solidity, Ethereum Blockchain, Foundry.

## Installation and Setup

```bash
forge install
forge build
forge test
```

### Deploy

```shell
$ forge script script/OkToken.s.sol:OkTokenScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```
