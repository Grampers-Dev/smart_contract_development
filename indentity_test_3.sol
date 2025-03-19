// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract XEAMToken is ERC20, Ownable, ReentrancyGuard {
    uint256 public constant INITIAL_SUPPLY = 2_000_000 * 10**18;
    uint256 public constant MAX_WALLET = (INITIAL_SUPPLY * 1) / 100; // 1%
    uint256 public constant MAX_TX = (INITIAL_SUPPLY * 5) / 10000; // 0.05%

    address public encouragementFund;
    address public emergencyFund;
    address public marketingWallet;
    address public stakingWallet;
    address public uniswapPair; // Address of the Uniswap pair (for sell detection)

    uint256 public constant BUY_TAX = 10;
    uint256 public constant SELL_TAX = 12;
    uint256 public constant SLIPPAGE = 13; // Between 13% and 17%

    mapping(address => bool) public isExcludedFromFees;

    event TaxDistributed(uint256 amount, string category);
    event UniswapPairUpdated(address newPair);

    constructor(
        address _encouragementFund,
        address _emergencyFund,
        address _marketingWallet,
        address _stakingWallet,
        address _initialUniswapPair
    ) ERC20("XEAM Token", "XEAM") Ownable(msg.sender) {
        encouragementFund = _encouragementFund;
        emergencyFund = _emergencyFund;
        marketingWallet = _marketingWallet;
        stakingWallet = _stakingWallet;
        uniswapPair = _initialUniswapPair;

        _mint(msg.sender, INITIAL_SUPPLY);
        isExcludedFromFees[msg.sender] = true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if (!isExcludedFromFees[msg.sender]) {
            require(
                balanceOf(recipient) + amount <= MAX_WALLET,
                "Exceeds max wallet limit"
            );
            require(amount <= MAX_TX, "Exceeds max transaction limit");
        }

        _transferWithTaxes(msg.sender, recipient, amount);
        return true;
    }

    function _transferWithTaxes(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 tax;
        uint256 lpShare;
        uint256 encouragementShare;
        uint256 emergencyShare;
        uint256 marketingShare;
        uint256 stakingShare;

        // Check if it's a buy or sell transaction
        if (recipient == uniswapPair) {
            // Sell transaction - 12% tax
            tax = (amount * SELL_TAX) / 100;
            lpShare = (tax * 4) / 12;          // 4% for LP
            encouragementShare = (tax * 4) / 12; // 4% for Encouragement Fund
            emergencyShare = (tax * 1) / 12;     // 1% for Emergency Fund
            marketingShare = (tax * 2) / 12;     // 2% for Marketing
            stakingShare = (tax * 1) / 12;      // 1% for Staking
        } else {
            // Buy transaction - 10% tax
            tax = (amount * BUY_TAX) / 100;
            lpShare = (tax * 3) / 10;          // 3% for LP
            encouragementShare = (tax * 4) / 10; // 4% for Encouragement Fund
            emergencyShare = (tax * 1) / 10;     // 1% for Emergency Fund
            marketingShare = (tax * 1) / 10;     // 1% for Marketing
            stakingShare = (tax * 1) / 10;      // 1% for Staking
        }

        uint256 netAmount = amount - tax;

        // Distribute the tax
        super._transfer(sender, encouragementFund, encouragementShare);
        emit TaxDistributed(encouragementShare, "Encouragement Fund");

        super._transfer(sender, emergencyFund, emergencyShare);
        emit TaxDistributed(emergencyShare, "Emergency Fund");

        super._transfer(sender, marketingWallet, marketingShare);
        emit TaxDistributed(marketingShare, "Marketing");

        super._transfer(sender, stakingWallet, stakingShare);
        emit TaxDistributed(stakingShare, "Staking");

        super._transfer(sender, address(this), lpShare);  // Transfer LP share to the contract
        emit TaxDistributed(lpShare, "Liquidity Pool");

        super._transfer(sender, recipient, netAmount);
    }

    function updateExcludedAccountStatus(address account, bool excluded)
        external
        onlyOwner
    {
        isExcludedFromFees[account] = excluded;
    }

    // Function to update the Uniswap pair address (temporary and later upgradeable)
    function updateUniswapPair(address newPair) external onlyOwner {
        require(newPair != address(0), "New pair address cannot be zero");
        uniswapPair = newPair;
        emit UniswapPairUpdated(newPair);
    }
}
