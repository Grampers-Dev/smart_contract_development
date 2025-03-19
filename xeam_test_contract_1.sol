// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract XEAMToken is ERC20, Ownable, ReentrancyGuard, Pausable {
    uint256 public constant INITIAL_SUPPLY = 2_000_000 * 10**18;
    uint256 public constant MAX_WALLET = (INITIAL_SUPPLY * 1) / 100; // 1%
    uint256 public constant MAX_TX = (INITIAL_SUPPLY * 5) / 10000; // 0.05%

    address public encouragementFund;
    address public emergencyFund;
    address public marketingWallet;
    address public stakingWallet;
    address public uniswapPair;

    uint256 public buyTax = 10;
    uint256 public sellTax = 12;

    mapping(address => bool) public isExcludedFromFees;

    event TaxDistributed(uint256 amount, string category);
    event UniswapPairUpdated(address newPair);
    event TaxesUpdated(uint256 newBuyTax, uint256 newSellTax);
    event LPFundsWithdrawn(uint256 amount);

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

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _applyTransferLimits(msg.sender, recipient, amount);
        _transferWithTaxes(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _applyTransferLimits(sender, recipient, amount);
        _transferWithTaxes(sender, recipient, amount);
        _approve(sender, msg.sender, allowance(sender, msg.sender) - amount);
        return true;
    }

    function _applyTransferLimits(address sender, address recipient, uint256 amount) internal view {
        if (!isExcludedFromFees[sender]) {
            require(balanceOf(recipient) + amount <= MAX_WALLET, "Exceeds max wallet limit");
            require(amount <= MAX_TX, "Exceeds max transaction limit");
        }
    }

    function _transferWithTaxes(address sender, address recipient, uint256 amount) internal {
        uint256 tax = (recipient == uniswapPair) ? (amount * sellTax) / 100 : (amount * buyTax) / 100;
        require(amount >= tax, "Tax exceeds transfer amount");

        uint256 netAmount = amount - tax;
        uint256 lpShare = (tax * 4) / 12;
        uint256 encouragementShare = (tax * 4) / 12;
        uint256 emergencyShare = (tax * 1) / 12;
        uint256 marketingShare = (tax * 2) / 12;
        uint256 stakingShare = (tax * 1) / 12;

        super._transfer(sender, encouragementFund, encouragementShare);
        emit TaxDistributed(encouragementShare, "Encouragement Fund");

        super._transfer(sender, emergencyFund, emergencyShare);
        emit TaxDistributed(emergencyShare, "Emergency Fund");

        super._transfer(sender, marketingWallet, marketingShare);
        emit TaxDistributed(marketingShare, "Marketing");

        super._transfer(sender, stakingWallet, stakingShare);
        emit TaxDistributed(stakingShare, "Staking");

        super._transfer(sender, address(this), lpShare);
        emit TaxDistributed(lpShare, "Liquidity Pool");

        super._transfer(sender, recipient, netAmount);
    }

    function withdrawLPFunds() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        require(balance > 0, "No LP funds available");
        super._transfer(address(this), owner(), balance);
        emit LPFundsWithdrawn(balance);
    }

    function updateExcludedAccountStatus(address account, bool excluded) external onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    function updateUniswapPair(address newPair) external onlyOwner {
        require(newPair != address(0), "New pair address cannot be zero");
        uniswapPair = newPair;
        emit UniswapPairUpdated(newPair);
    }

    function updateTaxes(uint256 _buyTax, uint256 _sellTax) external onlyOwner {
        require(_buyTax <= 15 && _sellTax <= 20, "Tax too high");
        buyTax = _buyTax;
        sellTax = _sellTax;
        emit TaxesUpdated(_buyTax, _sellTax);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
