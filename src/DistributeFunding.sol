// SPDX-License-Identifier: The Unlicense
pragma solidity >=0.8.17;

import "./BaseFunding.sol";
import "./SponsorFunding.sol";

contract DistributeFunding is BaseFunding {
    mapping(address => uint256) private amountOf;
    mapping(address => mapping(address => uint256)) private beneficiariesOf;
    mapping(address => uint256) private totalPercentageOf;
    mapping(address => address[]) private paidBeneficiaries;

    constructor() {
        owner = msg.sender;
    }

    modifier managerOnly() {
        require(amountOf[msg.sender] > 0, "You must be a crowdfunding manager");
        _;
    }

    modifier notAlreadyPaid(address _manager, address _beneficiary) {
        require(alreadyPaid(_manager, _beneficiary) == false, "The beneficiary was already paid");
        _;
    }

    function transferFunds(address _manager) external payable {
        amountOf[_manager] = msg.value;
    }

    function percentageSumOfBeneficiaries(address _manager, uint256 _percent) internal view returns (uint256) {
        return totalPercentageOf[_manager] + _percent;
    }

    function alreadyPaid(address _manager, address _beneficiary) internal view returns (bool) {
        uint256 length = paidBeneficiaries[_manager].length;

        for (uint256 i = 0; i < length; i++) {
            if (_beneficiary == paidBeneficiaries[_manager][i]) {
                return true;
            }
        }

        return false;
    }

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

    function withdrawBenefits(address _manager)
        external
        notAlreadyPaid(_manager, msg.sender)
        nonZero(beneficiariesOf[_manager][msg.sender])
    {
        payable(msg.sender).transfer((beneficiariesOf[_manager][msg.sender] * amountOf[_manager]) / 100);
        // the percentage total is not actualized because the sum that was withdrawn shouldn't be withdrawn ever again
        // the percentage is not actualized because it may be needed to check what percentage the beneficiary had
        // the amountOf[manager] is not actualized because the percentages are reliant on that value
        paidBeneficiaries[_manager].push(msg.sender);
    }

    function checkSelfPercentage(address _manager) external view returns (uint256) {
        return beneficiariesOf[_manager][msg.sender];
    }

    function checkSelfAmount() external view managerOnly returns (uint256) {
        return amountOf[msg.sender];
    }

    function checkSelfPaidBeneficiaries() external view managerOnly returns (address[] memory) {
        return paidBeneficiaries[msg.sender];
    }
}
