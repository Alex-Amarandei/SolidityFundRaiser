// SPDX-License-Identifier: The Unlicense
pragma solidity >=0.8.17;

import "./BaseFunding.sol";
import "./SponsorFunding.sol";
import "./DistributeFunding.sol";

struct Contributor {
    address sourceAddress;
    string firstName;
    string lastName;
}

enum Status {
    Unfunded,
    Prefunded,
    Funded
}

contract CrowdFunding is BaseFunding {
    uint256 public fundingGoal;

    Contributor[] private contributors;
    address private lastContributor;
    mapping(address => uint256) private contributionOf;

    Status private fundingStatus;

    constructor(uint256 _fundingGoal) {
        require(_fundingGoal > 0, "The funding goal must be greater than zero");
        fundingGoal = _fundingGoal;
        owner = msg.sender;
        fundingStatus = Status.Unfunded;
    }

    modifier withStatus(Status _status) {
        require(fundingStatus == _status, "This operation cannot be made with the current status");
        _;
    }

    function deposit(string calldata _firstName, string calldata _lastName)
        external
        payable
        nonZero(msg.value)
        withStatus(Status.Unfunded)
    {
        if (contributionOf[msg.sender] == 0) {
            Contributor memory contributor = Contributor(msg.sender, _firstName, _lastName);
            contributors.push(contributor);
        }
        contributionOf[msg.sender] += msg.value;
        lastContributor = msg.sender;

        if (address(this).balance >= fundingGoal) {
            fundingStatus = Status.Prefunded;
        }
    }

    function checkSelfContribution() external view returns (uint256) {
        return contributionOf[msg.sender];
    }

    function retrieveFunds(uint256 _amount) external nonZero(_amount) {
        require(contributionOf[msg.sender] >= _amount, "You do not have this much available");

        if (fundingStatus == Status.Prefunded) {
            if (msg.sender == lastContributor) {
                require(address(this).balance - _amount >= fundingGoal, "You can only withdraw the excess amount");

                contributionOf[msg.sender] -= _amount;
                payable(msg.sender).transfer(_amount);
            } else {
                revert("The withdrawal and receiving of funds is unavailable");
            }
        } else if (fundingStatus == Status.Unfunded) {
            contributionOf[msg.sender] -= _amount; // solhint-disable-line
            payable(msg.sender).transfer(_amount);
        } else {
            revert("The withdrawal and receiving of funds is unavailable");
        }
    }

    function notifySponsor(address payable _sponsorFunding) external ownerOnly withStatus(Status.Prefunded) {
        SponsorFunding sponsorFunding = SponsorFunding(_sponsorFunding);
        sponsorFunding.requestFunds();
    }

    function receiveSponsorship() external payable sponsorOnly {
        fundingStatus = Status.Funded;
    }

    function getStatusAsString(Status _status) internal pure returns (string memory) {
        if (_status == Status.Unfunded) return "Unfunded";
        if (_status == Status.Prefunded) return "Prefunded";
        return "Funded";
    }

    function getStatus() public view returns (string memory) {
        return getStatusAsString(fundingStatus);
    }

    function transferToDistribution(address _distributeFunding) external ownerOnly withStatus(Status.Funded) {
        DistributeFunding distributeFunding = DistributeFunding(_distributeFunding);
        distributeFunding.transferFunds{ value: address(this).balance }(msg.sender);
    }

    function resetCrowdFunding(uint256 _fundingGoal)
        external
        ownerOnly
        withStatus(Status.Funded)
        nonZero(_fundingGoal)
    {
        require(address(this).balance < fundingGoal, "The accrued funds must first be distributed before resetting");
        uint256 length = contributors.length;

        for (uint256 i = 0; i < length; i++) {
            contributionOf[contributors[i].sourceAddress] = 0;
        }

        delete contributors;
        lastContributor = address(0);
        fundingStatus = Status.Unfunded;
        fundingGoal = _fundingGoal;
    }
}
