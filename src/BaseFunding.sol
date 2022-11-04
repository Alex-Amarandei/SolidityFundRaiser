// SPDX-License-Identifier: The Unlicense
pragma solidity >=0.8.17;

contract BaseFunding {
    address public owner;

    modifier ownerOnly() {
        require(msg.sender == owner, "Only the contract owner is allowed to call this function");
        _;
    }

    modifier sponsorOnly() {
        require(tx.origin == owner, "Only the owner can request funds from the sponsor"); // solhint-disable-line
        _;
    }

    modifier nonZero(uint256 _value) {
        require(_value >= 1, "The value must be non-zero");
        _;
    }

    modifier lessThan100(uint256 _value) {
        require(_value <= 100, "The percentage amount cannot be more than 100%");
        _;
    }
}
