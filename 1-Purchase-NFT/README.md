## Project 1 – Purchase NFT with ERC20 Tokens

ERC721 NFT that can only be minted by paying with a specific ERC20 token. Each mint costs 1 unit of that token (`transferFrom` to the NFT contract, then mint).

**Contracts**

- **SANTANA** (ERC20) – OpenZeppelin-based token; anyone can `mint(amount)` (for testing).
- **SantanaNFT** (ERC721) – Constructor takes `IERC20` as payment token. `mint(amount)` requires `amount == 1`, sufficient balance and allowance, then transfers tokens and mints one NFT to the caller.

**Tests**

- **EndToEnd** – Deploys SANTANA and SantanaNFT, mints ERC20, approves and calls `nft.mint(1)`, asserts `totalSupply == 1`.

# Security and Disclaimer

This repository is educational and intentionally simple. It is not designed for mainnet use.
> DISCLAIMER: None of the code has been audited or undergone a security review, use at your own risk.
Treat all contracts here as training material only. Do not deploy them to handle real value without a professional security review.