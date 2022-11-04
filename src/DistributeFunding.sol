// SPDX-License-Identifier: The Unlicense
pragma solidity >=0.8.17;

import "./BaseFunding.sol";
import "./SponsorFunding.sol";

/// @title  A contract responsible with the fund distribution component
/// @author @Alex-Amarandei, @naclyy, @ochesanum
/// @notice Allows for multiple CrowdFundings simultaneoulsy, each handled by their respective manager
/// @dev    The owner does not have access to modify or view information
///         Each manager only has access to their individual share
contract DistributeFunding is BaseFunding {
    /// @notice The amount of funds corresponding to the CrowdFunding of a certain manager
    mapping(address => uint256) private amountOf;

    /// @notice The percentages of the beneficiaries of a certain crowd funding (identified by the manager's address)
    mapping(address => mapping(address => uint256)) private beneficiariesOf;

    /// @notice The percentage sum of the beneficiaries of a certain crowd funding (identified by the manager's address)
    mapping(address => uint256) private totalPercentageOf;

    /// @notice The addresses of the paid beneficiaries of a certain crowd funding (identified by the manager's address)
    mapping(address => address[]) private paidBeneficiaries;

    /// @notice Assigns the owner of the contract
    constructor() {
        owner = msg.sender;
    }

    /// @notice Only allows managers to perform call a certain function
    modifier managerOnly() {
        require(amountOf[msg.sender] > 0, "You must be a crowdfunding manager");
        _;
    }

    /// @notice Checks if the beneficiary in the manager's list has not been already paid
    /// @param  _manager The address of the manager of the targeted crowd funding funds
    /// @param  _beneficiary The address of one of the beneficiaries of the managed crowd funding
    modifier notAlreadyPaid(address _manager, address _beneficiary) {
        require(alreadyPaid(_manager, _beneficiary) == false, "The beneficiary was already paid");
        _;
    }

    /// @notice Called from a CrowdFunding Contract
    /// @param  _manager The address of the CrowdFunding Contract's owner, in this context referred to as manager
    function transferFunds(address _manager) external payable contractOnly {
        amountOf[_manager] = msg.value;
    }

    /// @notice Calculates if the current sum of percentages and the new one result in an invalid amount
    /// @param  _manager A crowdfunding manager's address
    /// @param  _percent The percent to add
    /// @return The total sum of percentages
    function percentageSumOfBeneficiaries(address _manager, uint256 _percent) internal view returns (uint256) {
        return totalPercentageOf[_manager] + _percent;
    }

    /// @notice Checks if the beneficiary in the manager's list has not been already paid
    /// @param  _manager The address of the manager of the targeted crowd funding funds
    /// @param  _beneficiary The address of one of the beneficiaries of the managed crowd funding
    /// @return The truth value of the assumption
    function alreadyPaid(address _manager, address _beneficiary) internal view returns (bool) {
        uint256 length = paidBeneficiaries[_manager].length;

        for (uint256 i = 0; i < length; i++) {
            if (_beneficiary == paidBeneficiaries[_manager][i]) {
                return true;
            }
        }

        return false;
    }

    /// @notice Allows a manager to add an extra beneficiary
    /// @dev    There are multiple conditions that need to be satisfied and are enforced by modifiers
    /// @param  _beneficiary The address of the beneficiary to add
    /// @param  _percent The percent to allocate to the beneficiary
    function addBeneficiary(address _beneficiary, uint256 _percent)
        external
        managerOnly
        nonZero(_percent)
        lessThan100(_percent)
        lessThan100(percentageSumOfBeneficiaries(msg.sender, _percent))
        notAlreadyPaid(msg.sender, _beneficiary)
    {
        beneficiariesOf[msg.sender][_beneficiary] = _percent;
        totalPercentageOf[msg.sender] += _percent;
    }

    /// @notice Allows a manager to modify the percent of a beneficiary
    /// @dev    The beneficiary must be existent and not paid before
    /// @param  _beneficiary The address of the beneficiary to update
    /// @param  _percent The percent to allocate to the beneficiary
    function updatePercentageOfBeneficiary(address _beneficiary, uint256 _percent)
        external
        managerOnly
        nonZero(_percent)
        notAlreadyPaid(msg.sender, _beneficiary)
        nonZero(beneficiariesOf[msg.sender][_beneficiary])
    {
        totalPercentageOf[msg.sender] -= beneficiariesOf[msg.sender][_beneficiary];
        require(
            percentageSumOfBeneficiaries(msg.sender, _percent) <= 100,
            "The percentages cannot amount to more than 100%"
        );

        beneficiariesOf[msg.sender][_beneficiary] = _percent;
        totalPercentageOf[msg.sender] += _percent;
    }

    /// @notice Allows a beneficiary to withdraw their corresponding share of a manager-administrated crowdfunding
    /// @param  _manager The address of the manager responsible with the crowdfunding
    /// @dev    The percentage total is not actualized because the percentage that was withdrawn is now blocked
    ///         The percentage is not actualized because it is now unmodifiable
    ///         The amountOf[manager] is not actualized because the benefits of others are reliant on that value
    function withdrawBenefits(address _manager)
        external
        notAlreadyPaid(_manager, msg.sender)
        nonZero(beneficiariesOf[_manager][msg.sender])
    {
        payable(msg.sender).transfer((beneficiariesOf[_manager][msg.sender] * amountOf[_manager]) / 100);
        paidBeneficiaries[_manager].push(msg.sender);
    }

    /// @notice Allows a beneficiary to check their share of a manager-administrated crowdfunding
    /// @param  _manager The address of the manager responsible with the crowdfunding
    /// @return The percent allocated to the beneficiary (the sender of the transaction)
    function checkSelfPercentage(address _manager) external view returns (uint256) {
        return beneficiariesOf[_manager][msg.sender];
    }

    /// @notice Allows a manager to check the amount gathered by the crowdfunding
    /// @return The funds corresponding to the manager's crowdfunding
    function checkSelfAmount() external view managerOnly returns (uint256) {
        return amountOf[msg.sender];
    }

    /// @notice Allows a manager to check the paid beneficiaries of its crowdfunding
    /// @return An array of the addresses of the paid beneficiaries
    function checkSelfPaidBeneficiaries() external view managerOnly returns (address[] memory) {
        return paidBeneficiaries[msg.sender];
    }
}
