pragma solidity ^0.8.26;

import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

interface IStakingPool {

    struct StakingInfo {
        uint256 stakedAmount;
        uint256 multiplier;
        uint256 lockedUntil;
    }

    error INVALID_LOCKING_PERIOD();
    error NOT_STAKED_YET();
    error ALREADY_STAKED();
    error INVALID_STAKE_AMOUNT();
    error NOT_REWARD_CONTROLLER();

    function initialize(ISuperToken _child) external;

    function stake(uint256 amount, uint256 lockingPeriod) external;

    function increaseStake(uint256 amount) external;

    function calculateMultiplier(uint256 lockingPeriod) external pure returns (uint256 multiplier);

    function retrieveMultiplier(uint128 units, uint256 stakedAmount) external pure returns (uint256 multiplier);

    function unstake(uint256 amount) external;

    function refreshDistributionFlow() external;

}
