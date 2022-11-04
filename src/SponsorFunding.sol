// SPDX-License-Identifier: The Unlicense
pragma solidity >=0.8.17;

import "./BaseFunding.sol";
import "./CrowdFunding.sol";

/// @title  A contract responsible with the sponsorship component
/// @author @Alex-Amarandei, @naclyy, @ochesanum
/// @notice Allows providing procentual sponsorships to whitelisted CrowdFunding Contracts
contract SponsorFunding is BaseFunding {
    /// @notice The percent of the amount with which to sponsor
    uint256 private percent;

    /// @notice True if the total amount accumulated is to be taken into account, false if only the funding goal is
    bool private totalCoverage;

    /// @notice whitelist[address] is true if the address has been whitelisted and false otherwise
    mapping(address => bool) private whitelist;

    /// @notice Sets the initial state of the sponsorship provider and initializes the attributes
    /// @dev    The constructor is payable in order to accomodate for providing an initial balance
    constructor() payable {
        owner = msg.sender;
        percent = 20;
        totalCoverage = true;
    }

    /// @notice Only allows whitelisted addresses to call a certain function
    modifier whitelistedOnly() {
        require(whitelist[msg.sender] == true, "This crowdfunder is not part of the whitelisted projects");
        _;
    }

    /// @notice Created for allowing funding by the owner of the contract
    /// @dev    Almost synonymous with: receive() external payable ownerOnly nonZero(msg.value) {}
    function deposit() external payable ownerOnly nonZero(msg.value) {}

    /// @notice Allows the owner to withdraw funds completely or partially
    /// @param  _amount The amount that the owner wants to withdraw from the contract
    function withdraw(uint256 _amount) external ownerOnly nonZero(_amount) {
        require(address(this).balance >= _amount, "You do not have this much available");
        payable(owner).transfer(_amount);
    }

    /// @notice Allows the owner to update the funding percent
    /// @param  _percent The new funding percent
    function updatePercent(uint256 _percent) external ownerOnly nonZero(_percent) {
        percent = _percent;
    }

    /// @notice Allows the owner to update the sponsorship coverage
    /// @param  _value The new value of the total coverage
    function setTotalCoverage(bool _value) external ownerOnly {
        totalCoverage = _value;
    }

    /// @notice  Allows the owner to whitelist contracts
    /// @param   _crowdFunder The CrowdFunding Contract address to whitelist
    function addToWhitelist(address _crowdFunder) external ownerOnly {
        whitelist[_crowdFunder] = true;
    }

    /// @notice Allows the owner to remove contracts from the whitelist
    /// @param  _crowdFunder The CrowdFunding Contract address to remove from the whitelist
    function removeFromWhitelist(address _crowdFunder) external ownerOnly {
        whitelist[_crowdFunder] = false;
    }

    /// @notice Called by a whitelisted CrowdFunding Contract to request funds
    /// @dev    The modifiers ensure that the address of the caller is a whitelisted contract
    ///         Also, the funding status is verified mathematically
    function requestFunds() external contractOnly whitelistedOnly {
        CrowdFunding crowdFunding = CrowdFunding(msg.sender);
        require(crowdFunding.fundingGoal() <= msg.sender.balance, "The contract did not raise enough funds");

        // the default sponsorhip choice
        uint256 sponsorship = (msg.sender.balance * percent) / 100;

        // updated if false
        if (!totalCoverage) {
            sponsorship = (crowdFunding.fundingGoal() * percent) / 100;
        }

        require(sponsorship <= address(this).balance, "There are not enough funds available to sponsor the contract");

        // even though there is the nonZero modifier, it can be used either at the very beginning or at the very end
        require(sponsorship > 0, "The amount to be transferred has to be non-zero");

        // calls the function in the CrowdFunding Contract and sends the corresponding funds
        crowdFunding.receiveSponsorship{ value: sponsorship }();
    }
}
