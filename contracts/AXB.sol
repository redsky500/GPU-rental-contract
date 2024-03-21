// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AiXBlock is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant TOTAL_SUPPLY = 300000000 * 10 ** 18; // Total supply of tokens

    // Vesting details for different allocations
    struct VestingDetails {
        uint256 allocation;
        uint256 cliff;
        uint256 initialVesting;
        uint256 vestingAfterCliff;
        uint256 monthlyLinear;
        uint256 vestingPeriod;
        uint256 vestingEndDate;
        uint256 tokensGeneratedEvent;
    }

    // Allocation details for each category
    mapping(string => VestingDetails) public allocations;
    mapping(string => uint256) public balances;

    constructor() ERC20("AiXBlock", "AXB") Ownable() {
        // Set up allocations
        allocations["Seed"] = VestingDetails({
            allocation: 7,
            cliff: 12,
            initialVesting: 1_719_730_800, //new Date(Date.UTC(2026, 11, 31, 7, 0, 0)).getTime()
            vestingAfterCliff: 1_751_266_800,
            monthlyLinear: 5,
            vestingPeriod: 19,
            vestingEndDate: 1_801_378_800,
            tokensGeneratedEvent: 1050000 * 10 ** 18
        });

        allocations["Private"] = VestingDetails({
            allocation: 10,
            cliff: 9,
            initialVesting: 1_719_730_800,
            vestingAfterCliff: 1_743_404_400,
            monthlyLinear: 5,
            vestingPeriod: 18,
            vestingEndDate: 1_790_751_600,
            tokensGeneratedEvent: 3000000 * 10 ** 18
        });

        allocations["Strategic"] = VestingDetails({
            allocation: 7,
            cliff: 18,
            initialVesting: 1_719_730_800,
            vestingAfterCliff: 1_767_164_400,
            monthlyLinear: 5,
            vestingPeriod: 19,
            vestingEndDate: 1_817_017_200,
            tokensGeneratedEvent: 1050000 * 10 ** 18
        });

        allocations["Public"] = VestingDetails({
            allocation: 6,
            cliff: 9,
            initialVesting: 1_719_730_800,
            vestingAfterCliff: 1_743_404_400,
            monthlyLinear: 5,
            vestingPeriod: 17,
            vestingEndDate: 1_788_159_600,
            tokensGeneratedEvent: 1050000 * 10 ** 18
        });

        allocations["Team/Advisor"] = VestingDetails({
            allocation: 15,
            cliff: 12,
            initialVesting: 1_751_266_800,
            vestingAfterCliff: 0,
            monthlyLinear: 5,
            vestingPeriod: 20,
            vestingEndDate: 1_803_798_000,
            tokensGeneratedEvent: 0
        });

        allocations["Rewards/Community"] = VestingDetails({
            allocation: 15,
            cliff: 1,
            initialVesting: 1_719_730_800,
            vestingAfterCliff: 1_722_409_200,
            monthlyLinear: 1,
            vestingPeriod: 95,
            vestingEndDate: 1_972_191_600,
            tokensGeneratedEvent: 2250000 * 10 ** 18
        });

        allocations["EcosystemGrowth"] = VestingDetails({
            allocation: 15,
            cliff: 12,
            initialVesting: 1_719_730_800,
            vestingAfterCliff: 1_751_266_800,
            monthlyLinear: 5,
            vestingPeriod: 18,
            vestingEndDate: 1_798_700_400,
            tokensGeneratedEvent: 4500000 * 10 ** 18
        });

        allocations["Reserves"] = VestingDetails({
            allocation: 25,
            cliff: 12,
            initialVesting: 1719730800,
            vestingAfterCliff: 1751266800,
            monthlyLinear: 5,
            vestingPeriod: 18,
            vestingEndDate: 1_798_700_400,
            tokensGeneratedEvent: 7500000 * 10 ** 18
        });

        // Mint tokens to allocations
        _mintAllocation("Seed");
        _mintAllocation("Private");
        _mintAllocation("Strategic");
        _mintAllocation("Public");
        _mintAllocation("Team/Advisor");
        _mintAllocation("Rewards/Community");
        _mintAllocation("EcosystemGrowth");
        _mintAllocation("Reserves");
    }

    // Mint tokens for an allocation
    function _mintAllocation(string memory allocationName) internal {
        VestingDetails storage allocation = allocations[allocationName];
        uint256 allocationAmount = TOTAL_SUPPLY.mul(allocation.allocation).div(100);
        _mint(address(this), allocationAmount);
    }

     // Function to release vested tokens based on vesting schedule
    function releaseVestedTokens(string memory allocationName) external onlyOwner {
        VestingDetails storage allocation = allocations[allocationName];
        require(block.timestamp >= allocation.initialVesting, "Vesting period has not started yet");

        uint256 vestedAmount = calculateVestedAmount(allocation, allocationName);
        _transfer(address(this), owner(), vestedAmount);
        balances[allocationName] += vestedAmount;
    }

    // Function to calculate vested amount based on vesting schedule
    function calculateVestedAmount(VestingDetails memory allocation, string memory allocationName) internal view returns (uint256) {
        if (block.timestamp < allocation.initialVesting) {
            return 0;
        } else if (allocation.initialVesting <= block.timestamp && block.timestamp < allocation.vestingAfterCliff) {
            if(balances[allocationName] >= allocation.tokensGeneratedEvent) {
                return 0;
            } else {
                return allocation.tokensGeneratedEvent;
            }
        } else if (block.timestamp >= allocation.vestingEndDate) {
            return TOTAL_SUPPLY.mul(allocation.allocation).div(100).sub(balances[allocationName]);
        } else {
            uint256 monthsSinceStart = (block.timestamp.sub(allocation.vestingAfterCliff)).div(30 days);
            uint256 monthlyVested = (TOTAL_SUPPLY.mul(allocation.allocation).div(100)).mul(allocation.monthlyLinear).div(100);
            return (allocation.tokensGeneratedEvent).add(monthsSinceStart.mul(monthlyVested)).sub(balances[allocationName]);
        }
    }
}
