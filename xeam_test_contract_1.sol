// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Import the ERC20 token standard implementation from OpenZeppelin
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Import Ownable to provide basic access control mechanism (owner-only functions)
import "@openzeppelin/contracts/access/Ownable.sol";
// Import ReentrancyGuard to prevent reentrant calls to functions
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// Import Pausable to allow pausing and unpausing of contract functions in emergencies
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title XEAMToken Contract
/// @notice This contract implements an ERC20 token with taxation on transfers, wallet and transaction limits,
/// and owner controlled functionalities such as pausing, updating fees, and withdrawing liquidity pool funds.
contract XEAMToken is ERC20, Ownable, ReentrancyGuard, Pausable {
    // Total initial token supply set to 2,000,000 tokens (adjusted for 18 decimal places)
    uint256 public constant INITIAL_SUPPLY = 2_000_000 * 10**18;
    // Maximum tokens a wallet can hold (1% of total supply)
    uint256 public constant MAX_WALLET = (INITIAL_SUPPLY * 1) / 100; // 1%
    // Maximum tokens allowed per transaction (0.05% of total supply)
    uint256 public constant MAX_TX = (INITIAL_SUPPLY * 5) / 10000; // 0.05%

    // Addresses for different funds where tax portions will be allocated
    address public encouragementFund;
    address public emergencyFund;
    address public marketingWallet;
    address public stakingWallet;
    // Address of the Uniswap pair (used to determine if a transfer is a sell)
    address public uniswapPair;

    // Tax rates for buying and selling (in percentage)
    uint256 public buyTax = 10;
    uint256 public sellTax = 12;

    // Mapping to keep track of addresses excluded from fees and limits
    mapping(address => bool) public isExcludedFromFees;

    // Events for logging tax distributions and administrative changes
    event TaxDistributed(uint256 amount, string category);
    event UniswapPairUpdated(address newPair);
    event TaxesUpdated(uint256 newBuyTax, uint256 newSellTax);
    event LPFundsWithdrawn(uint256 amount);

    /// @notice Constructor initializes the token details and sets up initial funds and exclusions.
    /// @param _encouragementFund Address to receive tax allocated for encouragement.
    /// @param _emergencyFund Address to receive tax allocated for emergencies.
    /// @param _marketingWallet Address to receive marketing tax.
    /// @param _stakingWallet Address to receive staking tax.
    /// @param _initialUniswapPair Address of the initial Uniswap pair.
    constructor(
        address _encouragementFund,
        address _emergencyFund,
        address _marketingWallet,
        address _stakingWallet,
        address _initialUniswapPair
    ) ERC20("XEAM Token", "XEAM") Ownable(msg.sender) {
        // Set the fund addresses
        encouragementFund = _encouragementFund;
        emergencyFund = _emergencyFund;
        marketingWallet = _marketingWallet;
        stakingWallet = _stakingWallet;
        uniswapPair = _initialUniswapPair;

        // Mint the entire initial supply to the contract deployer
        _mint(msg.sender, INITIAL_SUPPLY);
        // Exclude the owner from fees and transaction limits
        isExcludedFromFees[msg.sender] = true;
    }

    /// @notice Overrides the ERC20 transfer function to include transfer limits and tax deductions.
    /// @param recipient The address receiving the tokens.
    /// @param amount The number of tokens to transfer.
    /// @return True if the transfer was successful.
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        // Apply maximum wallet and transaction limits if sender is not excluded
        _applyTransferLimits(msg.sender, recipient, amount);
        // Process the transfer with the applicable taxes
        _transferWithTaxes(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Overrides the ERC20 transferFrom function to include transfer limits and tax deductions.
    /// @param sender The address sending the tokens.
    /// @param recipient The address receiving the tokens.
    /// @param amount The number of tokens to transfer.
    /// @return True if the transfer was successful.
    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        // Apply maximum wallet and transaction limits if sender is not excluded
        _applyTransferLimits(sender, recipient, amount);
        // Process the transfer with the applicable taxes
        _transferWithTaxes(sender, recipient, amount);
        // Decrease the allowance accordingly
        _approve(sender, msg.sender, allowance(sender, msg.sender) - amount);
        return true;
    }

    /// @notice Internal function to enforce maximum wallet and transaction limits.
    /// @param sender The address sending tokens.
    /// @param recipient The address receiving tokens.
    /// @param amount The number of tokens to transfer.
    function _applyTransferLimits(address sender, address recipient, uint256 amount) internal view {
        // Check limits only if the sender is not excluded from fees
        if (!isExcludedFromFees[sender]) {
            // Ensure the recipient's balance does not exceed the maximum wallet limit after transfer
            require(balanceOf(recipient) + amount <= MAX_WALLET, "Exceeds max wallet limit");
            // Ensure the transfer amount does not exceed the maximum transaction limit
            require(amount <= MAX_TX, "Exceeds max transaction limit");
        }
    }

    /// @notice Internal function to handle transfers by applying taxes and distributing them.
    /// @param sender The address sending tokens.
    /// @param recipient The address receiving tokens.
    /// @param amount The number of tokens to transfer.
    function _transferWithTaxes(address sender, address recipient, uint256 amount) internal {
        // Determine the tax based on whether the transfer is a sell (to the Uniswap pair) or a buy
        uint256 tax = (recipient == uniswapPair) ? (amount * sellTax) / 100 : (amount * buyTax) / 100;
        // Ensure that the tax does not exceed the transfer amount
        require(amount >= tax, "Tax exceeds transfer amount");

        // Calculate the net amount to send to the recipient after tax deduction
        uint256 netAmount = amount - tax;

        // Divide the tax into parts for different funds
        uint256 lpShare = (tax * 4) / 12;            // 4/12 share for Liquidity Pool (held in contract)
        uint256 encouragementShare = (tax * 4) / 12;   // 4/12 share for the Encouragement Fund
        uint256 emergencyShare = (tax * 1) / 12;         // 1/12 share for the Emergency Fund
        uint256 marketingShare = (tax * 2) / 12;         // 2/12 share for Marketing
        uint256 stakingShare = (tax * 1) / 12;           // 1/12 share for Staking

        // Transfer tax portions to respective funds and emit events for each distribution
        super._transfer(sender, encouragementFund, encouragementShare);
        emit TaxDistributed(encouragementShare, "Encouragement Fund");

        super._transfer(sender, emergencyFund, emergencyShare);
        emit TaxDistributed(emergencyShare, "Emergency Fund");

        super._transfer(sender, marketingWallet, marketingShare);
        emit TaxDistributed(marketingShare, "Marketing");

        super._transfer(sender, stakingWallet, stakingShare);
        emit TaxDistributed(stakingShare, "Staking");

        // Transfer LP share to the contract itself (to be later withdrawn by the owner)
        super._transfer(sender, address(this), lpShare);
        emit TaxDistributed(lpShare, "Liquidity Pool");

        // Finally, transfer the net amount to the recipient
        super._transfer(sender, recipient, netAmount);
    }

    /// @notice Allows the owner to withdraw accumulated liquidity pool funds from the contract.
    function withdrawLPFunds() external onlyOwner {
        // Check the contract's token balance (LP funds)
        uint256 balance = balanceOf(address(this));
        require(balance > 0, "No LP funds available");
        // Transfer the LP funds from the contract to the owner
        super._transfer(address(this), owner(), balance);
        emit LPFundsWithdrawn(balance);
    }

    /// @notice Updates the fee exclusion status of a given account.
    /// @param account The address to update.
    /// @param excluded Boolean indicating if the account should be excluded from fees.
    function updateExcludedAccountStatus(address account, bool excluded) external onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    /// @notice Updates the Uniswap pair address used for determining sell transactions.
    /// @param newPair The new Uniswap pair address.
    function updateUniswapPair(address newPair) external onlyOwner {
        require(newPair != address(0), "New pair address cannot be zero");
        uniswapPair = newPair;
        emit UniswapPairUpdated(newPair);
    }

    /// @notice Updates the tax rates for buy and sell transactions.
    /// @param _buyTax New buy tax percentage.
    /// @param _sellTax New sell tax percentage.
    function updateTaxes(uint256 _buyTax, uint256 _sellTax) external onlyOwner {
        // Ensure the new tax rates are within acceptable limits
        require(_buyTax <= 15 && _sellTax <= 20, "Tax too high");
        buyTax = _buyTax;
        sellTax = _sellTax;
        emit TaxesUpdated(_buyTax, _sellTax);
    }

    /// @notice Pauses all token transfers. Can only be called by the owner.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses token transfers. Can only be called by the owner.
    function unpause() external onlyOwner {
        _unpause();
    }
}

