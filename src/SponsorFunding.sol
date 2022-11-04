// SPDX-License-Identifier: The Unlicense
pragma solidity >=0.8.17;

import "./BaseFunding.sol";
import "./CrowdFunding.sol";

contract SponsorFunding is BaseFunding {
    uint256 private percent;
    bool private totalCoverage;

    mapping(address => bool) private whitelist;

    constructor() payable {
        owner = msg.sender;
        percent = 20;
        totalCoverage = true;
    }

    modifier whitelistedOnly() {
        require(whitelist[msg.sender] == true, "This crowdfunder is not part of the whitelisted projects");
        _;
    }

    modifier contractOnly() {
        uint256 length;
        address sender = msg.sender;

        assembly {
            length := extcodesize(sender)
        }

        require(length > 0, "Only whitelisted CrowdFunding Contracts can be sponsored");
        _;
    }

    // solhint-disable-next-line
    receive() external payable ownerOnly nonZero(msg.value) {}

    // function deposit() external payable ownerOnly nonZero(msg.value) {
    // }

    function withdraw(uint256 _amount) external ownerOnly {
        require(address(this).balance >= _amount, "You do not have this much available");
        payable(owner).transfer(_amount);
    }

    function updatePercent(uint256 _percent) external ownerOnly nonZero(_percent) {
        percent = _percent;
    }

    function setTotalCoverage(bool _value) external ownerOnly {
        totalCoverage = _value;
    }

    function addToWhitelist(address _crowdFunder) external ownerOnly {
        whitelist[_crowdFunder] = true;
    }

    function removeFromWhitelist(address _crowdFunder) external ownerOnly {
        whitelist[_crowdFunder] = false;
    }

    function requestFunds() external contractOnly whitelistedOnly {
        CrowdFunding crowdFunding = CrowdFunding(msg.sender);
        uint256 sponsorship = (msg.sender.balance * percent) / 100;

        if (!totalCoverage) {
            sponsorship = (crowdFunding.fundingGoal() * percent) / 100;
        }

        require(sponsorship <= address(this).balance, "There are not enough funds available to sponsor the contract");
        require(sponsorship > 0, "The amount to be transferred has to be non-zero");

        crowdFunding.receiveSponsorship{ value: sponsorship }();
    }
}
