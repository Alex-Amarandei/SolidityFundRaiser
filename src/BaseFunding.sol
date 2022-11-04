// SPDX-License-Identifier: The Unlicense
pragma solidity >=0.8.17;

/// @title  The base contract for a funding-related contract
/// @author @Alex-Amarandei, @naclyy, @ochesanum
/// @notice Includes the owner address and some commonly-used modifiers
/// @dev    Each contract using this as a base also has other modifiers
contract BaseFunding {
    /// @notice The owner of the funding-related contract
    /// @dev    Must be set in the constructor of each of the contracts
    address public owner;

    /// @notice Only allows the owner to execute a certain function
    modifier ownerOnly() {
        require(msg.sender == owner, "Only the contract owner is allowed to call this function");
        _;
    }

    /// @notice Only allows the owner to execute a sponsorship request
    /// @dev    The owner will initiate a sequence of calls mimicking a request and transfer flow
    ///         The origin of the flow must be none-other than the contract's owner
    modifier sponsorOnly() {
        require(tx.origin == owner, "Only the owner can request funds from the sponsor");
        _;
    }

    /// @notice Only allows contracts to call a certain function
    modifier contractOnly() {
        uint256 length;
        address sender = msg.sender;

        assembly {
            length := extcodesize(sender)
        }

        require(length > 0, "Only whitelisted CrowdFunding Contracts can be sponsored");
        _;
    }

    /// @notice Checks if `_value` (an unsigned integer) is greater than zero
    /// @param  _value The value to be checked
    modifier nonZero(uint256 _value) {
        require(_value > 0, "The value must be non-zero");
        _;
    }

    /// @notice Checks if `_value` (an unsigned integer) is smaller than a hundred
    /// @param  _value The value to be checked
    modifier lessThan100(uint256 _value) {
        require(_value <= 100, "The percentage amount cannot be more than 100%");
        _;
    }
}
