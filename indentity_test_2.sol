// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

    uint256 public constant BUY_TAX = 10;
    uint256 public constant SELL_TAX = 12;
    uint256 public constant SLIPPAGE = 13; // Between 13% and 17%

    mapping(address => bool) public isExcludedFromFees;

    event TaxDistributed(uint256 amount, string category);

    constructor(
        address _encouragementFund,
        address _emergencyFund,
        address _marketingWallet,
        address _stakingWallet
    ) ERC20("XEAM Token", "XEAM") Ownable(msg.sender) { // ✅ FIXED
        encouragementFund = _encouragementFund;
        emergencyFund = _emergencyFund;
        marketingWallet = _marketingWallet;
        stakingWallet = _stakingWallet;

        _mint(msg.sender, INITIAL_SUPPLY);
        isExcludedFromFees[msg.sender] = true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        require(
            balanceOf(recipient) + amount <= MAX_WALLET,
            "Exceeds max wallet limit"
        );
        require(amount <= MAX_TX, "Exceeds max transaction limit");

        _transferWithTaxes(msg.sender, recipient, amount);
        return true;
    }

    function _transferWithTaxes(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 taxAmount = (amount * SELL_TAX) / 100;
        uint256 sendAmount = amount - taxAmount;

        super._transfer(sender, encouragementFund, (taxAmount * 4) / 12);
        emit TaxDistributed((taxAmount * 4) / 12, "Encouragement Fund");

        super._transfer(sender, emergencyFund, (taxAmount * 1) / 12);
        emit TaxDistributed((taxAmount * 1) / 12, "Emergency Fund");

        super._transfer(sender, marketingWallet, (taxAmount * 4) / 12);
        emit TaxDistributed((taxAmount * 4) / 12, "Marketing");

        super._transfer(sender, stakingWallet, (taxAmount * 3) / 12);
        emit TaxDistributed((taxAmount * 3) / 12, "Staking");

        super._transfer(sender, recipient, sendAmount);
    }

    function updateExcludedAccountStatus(address account, bool excluded)
        external
        onlyOwner
    {
        isExcludedFromFees[account] = excluded;
    }
}

