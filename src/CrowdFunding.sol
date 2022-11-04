// SPDX-License-Identifier: The Unlicense
pragma solidity >=0.8.17;

import "./BaseFunding.sol";
import "./SponsorFunding.sol";
import "./DistributeFunding.sol";

/// @notice A structure representing a Contributor by the info provided alongside their donation
struct Contributor {
    address sourceAddress;
    string firstName;
    string lastName;
}

/// @notice An enum comprised of the various states that the crowdfunding may be in
enum Status {
    Unfunded,
    Prefunded,
    Funded
}

/// @title  A contract responsible with the fund raising component
/// @author @Alex-Amarandei, @naclyy, @ochesanum
/// @notice Allows raising funds, requesting sponsorships and transferring funds
/// @dev    Also acts as a communication point for the other two contracts
contract CrowdFunding is BaseFunding {
    /// @notice The goal of the fund raiser (in Wei)
    uint256 public fundingGoal;

    /// @notice An array of people who contributed to the fund raiser
    Contributor[] private contributors;

    /// @notice The address of the last contributor
    /// @dev    Remembered in order to allow for the last person who contributed to withdraw the excess amount
    address private lastContributor;

    /// @notice A mapping between the contributors and their respective contributions
    mapping(address => uint256) private contributionOf;

    /// @notice The current status of the fund raiser
    Status private fundingStatus;

    /// @notice Sets the initial state of the fund raiser to Unfunded and initializes the attributes
    /// @param  _fundingGoal The goal of the fund raiser (in Wei)
    /// @dev    The owner of the contract is set to the address who initiated the contract creation
    constructor(uint256 _fundingGoal) nonZero(_fundingGoal) {
        fundingGoal = _fundingGoal;
        owner = msg.sender;
        fundingStatus = Status.Unfunded;
    }

    /// @notice Verifies if the current status of the fund raiser is the one required to perform the operation
    /// @param  _status The status required to execute a certain function
    modifier withStatus(Status _status) {
        require(fundingStatus == _status, "This operation cannot be made with the current status");
        _;
    }

    /// @notice Allows anyone to deposit funds by providing their data
    /// @param  _firstName The first name of the contributor
    /// @param  _lastName  The last name of the contributor
    /// @dev    Modifiers ensure the proper conditions of execution
    ///         Strings may be empty to accomodate anonymous contributors
    function deposit(string calldata _firstName, string calldata _lastName)
        external
        payable
        nonZero(msg.value)
        withStatus(Status.Unfunded)
    {
        // a new Contributor is created if the address has no associated funds
        if (contributionOf[msg.sender] == 0) {
            Contributor memory contributor = Contributor(msg.sender, _firstName, _lastName);
            contributors.push(contributor);
        }

        // corresponding contribution of address is updated
        contributionOf[msg.sender] += msg.value;
        lastContributor = msg.sender;

        // it must be checked if the contribution has triggered a state change
        if (address(this).balance >= fundingGoal) {
            fundingStatus = Status.Prefunded;
        }
    }

    /// @notice Allows a person to check its contributon
    /// @dev    By default the contribution is zero, suitable for a non-contributor
    /// @return The contribution of the transaction's sender
    function checkSelfContribution() external view returns (uint256) {
        return contributionOf[msg.sender];
    }

    /// @notice Allows a person to retrieve their funds (completely or partially)
    /// @dev    Willingly decided not to delete the Contributor from the array in case of complete withdrawal
    ///         due to very high operation cost and insignificant impact (given that the object of interest)
    ///         is the contributed amount (which is, indeed, updated)
    /// @param  _amount The amount the contributor wants to withdraw
    function retrieveFunds(uint256 _amount) external nonZero(_amount) {
        require(contributionOf[msg.sender] >= _amount, "You do not have this much available");

        // In the Prefunded state only the last contributor is allowed to withdraw funds in case of excess
        if (fundingStatus == Status.Prefunded) {
            if (msg.sender == lastContributor) {
                require(address(this).balance - _amount >= fundingGoal, "You can only withdraw the excess amount");

                contributionOf[msg.sender] -= _amount;
                payable(msg.sender).transfer(_amount);
            } else {
                revert("The withdrawal and receiving of funds is unavailable");
            }
        }
        // Anyone that contributed can withdraw while in the Unfunded state
        else if (fundingStatus == Status.Unfunded) {
            contributionOf[msg.sender] -= _amount; 
            payable(msg.sender).transfer(_amount);
        }
        // Nobody can withdraw while in the Funded state
        else {
            revert("The withdrawal and receiving of funds is unavailable");
        }
    }

    /// @notice The owner can use this function to notify the sponsorship contract of its Prefunded State
    /// @dev    Calls the requestFunds function of the SponsorFunding Contract to trigger the call of the
    ///         receiveSponsorship in this contract
    /// @param  _sponsorFunding The address of the SponsorFunding Contract
    function notifySponsor(address _sponsorFunding) external ownerOnly withStatus(Status.Prefunded) {
        SponsorFunding sponsorFunding = SponsorFunding(_sponsorFunding);
        sponsorFunding.requestFunds();
    }

    /// @notice The SponsorFunding Contract calls this function to deposit funds
    /// @dev    Part of the same flow as the notifySponsor function
    ///         It was created because the receive function doesn't allow the change in status
    ///         and it is a necessary functionality to accomodate
    function receiveSponsorship() external payable sponsorOnly {
        fundingStatus = Status.Funded;
    }

    /// @notice Internal function that returns the string representation of the funding status
    /// @param  _status The status to be returned in string form
    /// @return The string version of the requested status
    function getStatusAsString(Status _status) internal pure returns (string memory) {
        if (_status == Status.Unfunded) return "Unfunded";
        if (_status == Status.Prefunded) return "Prefunded";
        return "Funded";
    }

    /// @notice The function exposed to any user who wants to check the current status of the fundraiser
    /// @return The string version of the fundraiser status
    function getStatus() public view returns (string memory) {
        return getStatusAsString(fundingStatus);
    }

    /// @notice Transfer the accumulated funds to the DistributeFunding Contract
    /// @param  _distributeFunding The address of the DistributeFunding Contract
    /// @dev    Only possible when the state is Funded, condition ensured by modifier
    function transferToDistribution(address _distributeFunding) external ownerOnly withStatus(Status.Funded) {
        DistributeFunding distributeFunding = DistributeFunding(_distributeFunding);
        distributeFunding.transferFunds{ value: address(this).balance }(msg.sender);
    }

    /// @notice Used to reset the fund raiser in order to start another one and not waste the contract
    /// @param  _fundingGoal The new goal of the fund raiser
    /// @dev    Only possible when the state is Funded, condition ensured by modifier
    ///         Only possible when the funds have already been distributed
    function resetCrowdFunding(uint256 _fundingGoal)
        external
        ownerOnly
        withStatus(Status.Funded)
        nonZero(_fundingGoal)
    {
        require(address(this).balance == 0, "The accrued funds must first be distributed before resetting");
        uint256 length = contributors.length;

        // resets all existing contributions in the mapping to zero
        for (uint256 i = 0; i < length; i++) {
            contributionOf[contributors[i].sourceAddress] = 0;
        }

        // deletes the contributors array
        delete contributors;

        // assign 0x0... to the last contributor
        lastContributor = address(0);

        // the status is yet again Unfunded
        fundingStatus = Status.Unfunded;

        // assigns the new funding goal
        fundingGoal = _fundingGoal;
    }
}
