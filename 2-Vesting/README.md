## Project 2 – Linear ERC20 Vesting

Time-locked ERC20 vesting contract where a payer deposits tokens for a receiver, and the receiver can withdraw `1/n` of the total per day over `n` days. The contract escrows the tokens and tracks how much has already been withdrawn.

**Contracts**

- **SANTANA** (ERC20) – OpenZeppelin-based token; anyone can `mint(amount)` (for testing).
- **Vesting** – Constructor takes an `IERC20` as the token to vest. `deposit(amount, numDays, receiver)` creates a linear vesting schedule from `msg.sender` (payer) to `receiver`. The receiver calls `withdraw(payer)` to claim the amount vested so far.

**Tests**

- **VestingTest** – Deploys `SANTANA` and `Vesting`, mints ERC20 to the payer, approves and calls `deposit`, warps time and calls `withdraw`, and asserts balances and schedule state across multiple scenarios (reverts, partial withdrawals, full vesting end-to-end).

# Security and Disclaimer

This repository is educational and intentionally simple. It is not designed for mainnet use.
> DISCLAIMER: None of the code has been audited or undergone a security review, use at your own risk.
Treat all contracts here as training material only. Do not deploy them to handle real value without a professional security review.

