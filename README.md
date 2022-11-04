# Fund Raiser - Homework 1

## Table of Contents

1. [Contract Requirements Breakdown](#contract-requirements-breakdown)
2. [Contract Extra Features](#contract-extra-features)
3. [Team Members](#team-members)

<br><hr><br>

## Contract Requirements Breakdown

### CrowdFunding

- _must include a funding goal_
- _must allow users to contribute to the goal_
- _must identify contributors by their address_
- _may retain other info_
- _must have a state (`Unfunded`, `Prefunded` or `Funded`)_
- _state must be updated when certain conditions are met_
- _contributors may withdraw funds during the `Unfunded` state_
- _must allow the owner to notify a sponsor_
- _must allow the owner to transfer the funds to a distribution contract when the `Funded` state is reached_

<br>

### SponsorFunding

- _must allow sponsoring via percent_
- _must have its own balance_
- _must be able to be initialized with a starting balance_
- _must revert the sponsorship if there are not enough funds_
- _must allow the owner to change the sponsorhip percent_
- _must allow the owner to fund the contract_
- _must verifiy the `CrowdFunding` contract's balance_

<br>

### DistributeFunding

- _must allow adding beneficiaries with certain shares_
- _the total shares may amount to less than a hundred_
- _must allow the `CrowdFunding` to transfer funds_
- _must allow beneficiaries to withdraw their respective shares_

<br>

## Contract Extra Features

**Mention:** _All the functionalities above are implemented and will not be listed again below to make reading easier_

### BaseFunding

- base contract for the following three
- comprised of the `owner` attribute and shared modifiers

### CrowdFunding\*

- _status implemented as enum_
- _current funding status returned in string format_
- _both contributors and their respective contributions are retained_
- _custom modifiers created to avoid redundancy and make the code cleaner while enforcing security and strictness_
- _the last contributor is allowed to withdraw its funds if the total balance accumulated exceeds the funding goal_
- _contributors can check their respective contributions_
- _function exposed to receive funds from sponsor_
- _possibility to reset the crowd funding once all the funds have been transferred and the status is `Funded`_

<br>

### SponsorFunding\*

- _numerous custom modifiers used for enforcing security_
- _allows for choosing between sponsoring with a percentage of the funding goal or the total accumulated balance of the
  `CrowdFunding` contract_
- _allows the owner to whitelist certain `CrowdFunding` contracts_
- _checks the fund requests comes from a whitelisted contract and not an **EOA**_
- _allows the owner to remove addresses from the whitelist_

<br>

### DistributeFunding\*

- _allows for multiple crowdfundings to use the facilities of the contract by uniquely identifying every `CrowdFunding`
  by the address of its owner (referred to as **manager** below)_
- _each manager only has access to the info that concerns them_
- _the amount gathered by each manager is updated alongside the transfer from the `CrowdFunding` contract_
- _each manager has a corresponding list of beneficiaries, each with their own respective percentages_
- _total percentages allocated are remembered for each of the managers in order to avoid recalculating them each time a
  beneficiary is added/updated_
- _beneficiaries can be added by a manager to their mapping_
- _beneficiaries can have their shares updated by a manager_
- _proper fund administration is thouroughly ensured by numerous checks using custom modifiers_
- _beneficiaries can check their respective share_
- _managers can check the amount gathered_
- _managers can check the addresses of the paid beneficiaries_

**Documentation:** _All the contracts have been meticulously documented using `NatSpec`._

<br>

## Team Members

- [Amarandei Alexandru](https://github.com/Alex-Amarandei)
- [Ochesanu Mihnea](https://github.com/ochesanum)
- [Zaharia Andrei](https://github.com/naclyy)
