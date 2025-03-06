// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AddressClaim is Ownable, Pausable {
    mapping(address => bool) private _claimedAddresses;

    event AddressClaimedEvent(address indexed claimant);

    constructor() Ownable(msg.sender) {}

    /// @dev Allows an address to claim itself.
    function claimAddress() public whenNotPaused {
        require(!_claimedAddresses[msg.sender], "Address already claimed");
        _claimedAddresses[msg.sender] = true;
        emit AddressClaimedEvent(msg.sender);
    }

    /// @dev Checks if an address has been claimed.
    function isAddressClaimed(address claimant) public view returns (bool) {
        return _claimedAddresses[claimant];
    }

    /// @dev Allows an address to unclaim itself.
    function unclaimAddress() public whenNotPaused {
        require(_claimedAddresses[msg.sender], "Address not claimed");
        _claimedAddresses[msg.sender] = false;
    }

    /// @dev Pauses the contract. Only the owner can call this function.
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev Unpauses the contract. Only the owner can call this function.
    function unpause() public onlyOwner {
        _unpause();
    }
}