pragma solidity ^0.8.26;

import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { ISuperfluidPool } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

interface IStakingPool {

    struct StakingInfo {
        uint256 stakedAmount;
        uint256 lockedUntil;
    }

    error INVALID_LOCKING_PERIOD();
    error NOT_STAKED_YET();
    error ALREADY_STAKED();
    error LOCK_NOT_EXPIRED();
    error INVALID_STAKE_AMOUNT();
    error NOT_REWARD_CONTROLLER();
    error INSUFFICIENT_STAKED_AMOUNT();
    error TOKENS_STILL_LOCKED();

    function SPIRIT() external view returns (ISuperToken);
    function child() external view returns (ISuperToken);
    function REWARD_CONTROLLER() external view returns (address);
    function distributionPool() external view returns (ISuperfluidPool);
    function MINIMUM_LOCKING_PERIOD() external view returns (uint256);
    function MAXIMUM_LOCKING_PERIOD() external view returns (uint256);
    function MINIMUM_STAKE_AMOUNT() external view returns (uint256);
    function BASE_MULTIPLIER() external view returns (uint256);
    function MULTIPLIER_RANGE() external view returns (uint256);
    function TIME_RANGE() external view returns (uint256);

    function initialize(ISuperToken _child) external;

    function stake(uint256 amount, uint256 lockingPeriod) external;

    function increaseStake(uint256 amount) external;

    function extendLockingPeriod(uint256 newLockingPeriod) external;

    function calculateMultiplier(uint256 lockingPeriod) external pure returns (uint256 multiplier);

    function retrieveMultiplier(uint128 units, uint256 stakedAmount) external pure returns (uint256 multiplier);

    function unstake(uint256 amount) external;

    function refreshDistributionFlow() external;

    function getStakingInfo(address staker) external view returns (StakingInfo memory stakingInfo);

}
