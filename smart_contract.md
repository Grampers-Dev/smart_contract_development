# XEAMToken Breakdown

## Contract Overview

- **Token Name**: XEAM Token
- **Token Symbol**: XEAM
- **Initial Supply**: 2,000,000 XEAM
- **Decimals**: 18
- **Maximum Wallet Size**: 1% of the total supply (20,000 XEAM)
- **Maximum Transaction Size**: 0.05% of the total supply (1,000 XEAM)

---

## Tax Breakdown

### Buy Tax (10%):
When a user buys the token, the following tax breakdown applies:

| **Category**            | **Percentage** | **Amount** (per 1,000 XEAM) |
|-------------------------|----------------|-----------------------------|
| Liquidity Pool (LP)      | 3%             | 30 XEAM                     |
| Encouragement Fund       | 4%             | 40 XEAM                     |
| Emergency Fund           | 1%             | 10 XEAM                     |
| Marketing Wallet         | 1%             | 10 XEAM                     |
| Staking Wallet           | 1%             | 10 XEAM                     |
| **Total Tax**            | **10%**        | **100 XEAM**                |

---

### Sell Tax (12%):
When a user sells the token, the following tax breakdown applies:

| **Category**            | **Percentage** | **Amount** (per 1,000 XEAM) |
|-------------------------|----------------|-----------------------------|
| Liquidity Pool (LP)      | 4%             | 40 XEAM                     |
| Encouragement Fund       | 4%             | 40 XEAM                     |
| Emergency Fund           | 1%             | 10 XEAM                     |
| Marketing Wallet         | 2%             | 20 XEAM                     |
| Staking Wallet           | 1%             | 10 XEAM                     |
| **Total Tax**            | **12%**        | **120 XEAM**                |

---

![Tax System](/newplot.png)


## Key Contract Features

| **Feature**                   | **Description**                                                                 |
|-------------------------------|---------------------------------------------------------------------------------|
| **`MAX_WALLET`**               | Maximum wallet size: 1% of total supply (20,000 XEAM)                            |
| **`MAX_TX`**                   | Maximum transaction size: 0.05% of total supply (1,000 XEAM)                    |
| **`BUY_TAX`**                  | Tax on buys: 10%                                                                |
| **`SELL_TAX`**                 | Tax on sells: 12%                                                               |
| **`SLIPPAGE`**                 | Allows slippage between 13% and 17% for transactions                            |
| **`isExcludedFromFees`**       | Mapping to exclude specific accounts from taxes (e.g., contract owner)         |
| **`uniswapPair`**              | Address of the Uniswap liquidity pool for detecting buys/sells                 |

---

## Tax Distribution

- **Encouragement Fund**: Supports charity or community efforts.
- **Emergency Fund**: Reserved for unforeseen emergencies or situations.
- **Marketing Wallet**: For ongoing marketing campaigns and partnerships.
- **Staking Wallet**: For token staking incentives and rewards.
- **Liquidity Pool**: Ensures liquidity in decentralized exchanges like Uniswap.

---

## Contract Functions

| **Function**                               | **Description**                                                                 |
|--------------------------------------------|---------------------------------------------------------------------------------|
| **`transfer(address recipient, uint256 amount)`** | Handles transfers with tax logic and ensures max wallet and transaction limits. |
| **`_transferWithTaxes(address sender, address recipient, uint256 amount)`** | Distributes tax to respective categories (LP, encouragement fund, etc.).       |
| **`updateExcludedAccountStatus(address account, bool excluded)`** | Excludes specific accounts from tax logic (e.g., owner or liquidity provider). |
| **`updateUniswapPair(address newPair)`**  | Allows updating the Uniswap pair address for detecting buy/sell transactions.  |

---

## Deployment & Upgrade

- **Temporary Uniswap Pair Address**: On deployment, the `uniswapPair` can be set to a temporary address.
- **Update LP Address**: The contract owner can later call `updateUniswapPair` to set the correct LP address when available.

---
