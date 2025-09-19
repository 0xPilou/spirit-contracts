pragma solidity ^0.8.26;

/* Openzeppelin Contracts & Interfaces */

import { Initializable } from "@openzeppelin-v5/contracts/proxy/utils/Initializable.sol";
import { SafeCast } from "@openzeppelin-v5/contracts/utils/math/SafeCast.sol";

/* Superfluid Protocol Contracts & Interfaces */
import { SuperTokenV1Library } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {
    ISuperToken,
    ISuperfluidPool,
    PoolConfig
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import { IStakingPool } from "src/interfaces/core/IStakingPool.sol";

using SuperTokenV1Library for ISuperToken;
using SafeCast for int256;

contract StakingPool is IStakingPool, Initializable {

    ISuperToken public immutable SPIRIT;
    address public immutable REWARD_CONTROLLER;
    ISuperToken public child;

    uint256 public constant MINIMUM_STAKE_AMOUNT = 1e18; // (1 SPIRIT);
    uint256 public constant MINIMUM_LOCKING_PERIOD = 4 weeks;
    uint256 public constant MAXIMUM_LOCKING_PERIOD = 52 weeks;
    uint256 public constant STREAM_OUT_DURATION = 1 weeks;

    uint256 public constant TIME_RANGE = MAXIMUM_LOCKING_PERIOD - MINIMUM_LOCKING_PERIOD;

    uint256 public constant BASE_MULTIPLIER = 10_000;
    uint256 public constant MULTIPLIER_RANGE = 110_000;

    uint256 private constant _DOWNSCALER = 1e18;

    ISuperfluidPool public distributionPool;

    mapping(address staker => StakingInfo stakingInfo) public stakingInfo;

    constructor(ISuperToken _spirit, address _rewardController) {
        _disableInitializers();

        SPIRIT = _spirit;
        REWARD_CONTROLLER = _rewardController;
    }

    function initialize(ISuperToken _child) external initializer {
        child = _child;

        // Superfluid GDA Pool configuration
        PoolConfig memory poolConfig =
            PoolConfig({ transferabilityForUnitsOwner: false, distributionFromAnyAddress: false });

        // Create Superfluid GDA Pool
        distributionPool = SPIRIT.createPool(address(this), poolConfig);

        // Bootstrap the pool with 1 unit for the PoolAdmin itself (this contract)
        distributionPool.updateMemberUnits(address(this), 1);
    }

    function stake(uint256 amount, uint256 lockingPeriod) external {
        StakingInfo storage userStakingInfo = stakingInfo[msg.sender];

        // Check if user has already staked tokens
        if (userStakingInfo.lockedUntil > 0) {
            revert ALREADY_STAKED();
        }

        if (amount < MINIMUM_STAKE_AMOUNT) {
            revert INVALID_STAKE_AMOUNT();
        }

        // Validate locking period
        if (lockingPeriod < MINIMUM_LOCKING_PERIOD || lockingPeriod > MAXIMUM_LOCKING_PERIOD) {
            revert INVALID_LOCKING_PERIOD();
        }

        // Calculate bonus multiplier based on locking period
        uint256 multiplier = calculateMultiplier(lockingPeriod);

        // Calculate units with multiplier applied (multiplier is in basis points)
        uint128 units = uint128((amount / _DOWNSCALER) * multiplier / BASE_MULTIPLIER);

        // Store staking information
        userStakingInfo.stakedAmount = amount;
        userStakingInfo.multiplier = multiplier;
        userStakingInfo.lockedUntil = block.timestamp + lockingPeriod;

        distributionPool.updateMemberUnits(msg.sender, units);
        child.transferFrom(msg.sender, address(this), amount);
    }

    function increaseStake(uint256 amount) external {
        StakingInfo storage userStakingInfo = stakingInfo[msg.sender];

        // Check if user has already staked tokens
        if (userStakingInfo.lockedUntil == 0) {
            revert NOT_STAKED_YET();
        }

        if (amount < MINIMUM_STAKE_AMOUNT) {
            revert INVALID_STAKE_AMOUNT();
        }

        uint256 lockingPeriod = userStakingInfo.lockedUntil - block.timestamp;

        // Calculate bonus multiplier based on locking period
        uint256 multiplier = calculateMultiplier(lockingPeriod);

        uint128 currentUnits = distributionPool.getUnits(msg.sender);

        // Calculate units with multiplier applied
        uint128 newUnits = currentUnits + uint128((amount / _DOWNSCALER) * multiplier / BASE_MULTIPLIER);

        // Store staking information
        userStakingInfo.stakedAmount += amount;
        userStakingInfo.multiplier = retrieveMultiplier(newUnits, userStakingInfo.stakedAmount);

        distributionPool.updateMemberUnits(msg.sender, newUnits);
        child.transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Calculate bonus multiplier based on locking period
     * @dev Linear function: 4 week = 10_000 (1x), 52 weeks (365 days) = 120_000 (12x)
     * @param lockingPeriod The locking period in seconds
     * @return multiplier The bonus multiplier in basis points (10_000 = 1x, 120_000 = 12x)
     */
    function calculateMultiplier(uint256 lockingPeriod) public pure returns (uint256 multiplier) {
        multiplier = BASE_MULTIPLIER + ((lockingPeriod - MINIMUM_LOCKING_PERIOD) * MULTIPLIER_RANGE) / TIME_RANGE;
    }

    function retrieveMultiplier(uint128 units, uint256 stakedAmount) public pure returns (uint256 multiplier) {
        multiplier = (uint256(units) * BASE_MULTIPLIER * _DOWNSCALER) / stakedAmount;
    }

    function unstake(uint256 amount) external {
        StakingInfo memory info = stakingInfo[msg.sender];

        // Check if user has staked tokens
        require(info.stakedAmount > 0, "No staked tokens");

        // Check if user is trying to unstake more than they have
        require(amount <= info.stakedAmount, "Insufficient staked amount");

        // Check locking period - user can only unstake after lock period expires
        require(block.timestamp >= info.lockedUntil, "Tokens still locked");

        // Calculate units to remove (with original multiplier applied, multiplier is in basis points)
        uint128 unitsToRemove = uint128((amount * info.multiplier) / (10_000 * _DOWNSCALER));

        // Update member units
        distributionPool.updateMemberUnits(msg.sender, unitsToRemove);

        // Update staking info
        stakingInfo[msg.sender].stakedAmount -= amount;

        // If all tokens are unstaked, reset the staking info
        if (stakingInfo[msg.sender].stakedAmount == 0) {
            delete stakingInfo[msg.sender];
        }

        // Transfer staked tokens back to user
        child.transfer(msg.sender, amount);
    }

    function refreshDistributionFlow() external onlyRewardController {
        // Calculate the flowrate of the SPIRIT tokens to be distributed
        int96 flowRate = int256(SPIRIT.balanceOf(address(this)) / STREAM_OUT_DURATION).toInt96();

        SPIRIT.distributeFlow(address(this), distributionPool, flowRate);
    }

    modifier onlyRewardController() {
        if (msg.sender != REWARD_CONTROLLER) {
            revert NOT_REWARD_CONTROLLER();
        }
        _;
    }

}
