pragma solidity ^0.8.26;

/* Openzeppelin Imports */
import { Initializable } from "@openzeppelin-v5/contracts/proxy/utils/Initializable.sol";
import { SafeCast } from "@openzeppelin-v5/contracts/utils/math/SafeCast.sol";

/* Superfluid Imports */
import { SuperTokenV1Library } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { ISuperfluidPool } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { PoolConfig } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/* Local Imports */
import { IStakingPool } from "src/interfaces/core/IStakingPool.sol";

/* Library Settings */
using SuperTokenV1Library for ISuperToken;
using SafeCast for int256;

contract StakingPool is IStakingPool, Initializable {

    //      ____                          __        __    __        _____ __        __
    //     /  _/___ ___  ____ ___  __  __/ /_____ _/ /_  / /__     / ___// /_____ _/ /____  _____
    //     / // __ `__ \/ __ `__ \/ / / / __/ __ `/ __ \/ / _ \    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   _/ // / / / / / / / / / / /_/ / /_/ /_/ / /_/ / /  __/   ___/ / /_/ /_/ / /_/  __(__  )
    //  /___/_/ /_/ /_/_/ /_/ /_/\__,_/\__/\__,_/_.___/_/\___/   /____/\__/\__,_/\__/\___/____/

    ISuperToken public immutable SPIRIT;
    address public immutable REWARD_CONTROLLER;
    ISuperToken public child;

    uint256 public constant MINIMUM_STAKE_AMOUNT = 1e18; // (1 SPIRIT);
    uint256 public constant MINIMUM_LOCKING_PERIOD = 1 weeks;
    uint256 public constant MAXIMUM_LOCKING_PERIOD = 156 weeks;
    uint256 public constant STREAM_OUT_DURATION = 1 weeks;

    uint256 public constant TIME_RANGE = MAXIMUM_LOCKING_PERIOD - MINIMUM_LOCKING_PERIOD;

    uint256 public constant MIN_MULTIPLIER = 10_000;
    uint256 public constant MAX_MULTIPLIER = 360_000;
    uint256 public constant MULTIPLIER_RANGE = MAX_MULTIPLIER - MIN_MULTIPLIER;

    uint256 private constant _DOWNSCALER = 1e18;
    uint256 private constant _STAKEHOLDER_AMOUNT = 250_000_000 ether;
    uint256 private constant _STAKEHOLDER_LOCKING_PERIOD = 52 weeks;

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    ISuperfluidPool public distributionPool;

    mapping(address staker => StakingInfo stakingInfo) private _stakingInfo;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    constructor(ISuperToken _spirit, address _rewardController) {
        _disableInitializers();

        SPIRIT = _spirit;
        REWARD_CONTROLLER = _rewardController;
    }

    function initialize(ISuperToken _child, address artist, address agent) external initializer {
        child = _child;

        // Superfluid GDA Pool configuration
        PoolConfig memory poolConfig =
            PoolConfig({ transferabilityForUnitsOwner: false, distributionFromAnyAddress: false });

        // Create Superfluid GDA Pool
        distributionPool = SPIRIT.createPool(address(this), poolConfig);

        // Bootstrap the pool with 1 unit for the PoolAdmin itself
        // Note : ensure that even if every stakers unstake, the distribution flow will keep running
        distributionPool.updateMemberUnits(address(this), 1);

        _stake(artist, _STAKEHOLDER_AMOUNT, _STAKEHOLDER_LOCKING_PERIOD);
        _stake(agent, _STAKEHOLDER_AMOUNT, _STAKEHOLDER_LOCKING_PERIOD);
    }

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function stake(uint256 amount, uint256 lockingPeriod) external {
        _stake(msg.sender, amount, lockingPeriod);
    }

    function increaseStake(uint256 amount) external {
        // Check if the amount is valid
        if (amount < MINIMUM_STAKE_AMOUNT) {
            revert INVALID_STAKE_AMOUNT();
        }

        StakingInfo storage userStakingInfo = _stakingInfo[msg.sender];

        // Check if user has already staked tokens
        if (userStakingInfo.lockedUntil == 0) {
            revert NOT_STAKED_YET();
        }

        uint256 multiplier;

        // Use the min multiplier if:
        // 1. increasing stake less than 1 week before the locking period expires)
        // 2. the locking period is already expired
        if (block.timestamp + MINIMUM_LOCKING_PERIOD > userStakingInfo.lockedUntil) {
            multiplier = MIN_MULTIPLIER;
        } else {
            multiplier = calculateMultiplier(userStakingInfo.lockedUntil - block.timestamp);
        }

        // Calculate units with multiplier applied
        uint128 unitsToAdd = uint128((amount * multiplier) / (MIN_MULTIPLIER * _DOWNSCALER));

        // Store staking information
        userStakingInfo.stakedAmount += amount;

        distributionPool.increaseMemberUnits(msg.sender, unitsToAdd);
        child.transferFrom(msg.sender, address(this), amount);
    }

    function extendLockingPeriod(uint256 newLockingPeriod) external {
        StakingInfo storage userStakingInfo = _stakingInfo[msg.sender];

        // Check if user has already staked tokens
        if (userStakingInfo.lockedUntil == 0) {
            revert NOT_STAKED_YET();
        }

        // Check if the locking period is already expired
        if (userStakingInfo.lockedUntil > block.timestamp) {
            revert LOCK_NOT_EXPIRED();
        }

        if (newLockingPeriod < MINIMUM_LOCKING_PERIOD || newLockingPeriod > MAXIMUM_LOCKING_PERIOD) {
            revert INVALID_LOCKING_PERIOD();
        }

        // Calculate the multiplier for the new locking period
        uint256 multiplier = calculateMultiplier(newLockingPeriod);

        // Calculate units with multiplier applied
        uint128 unitsToAdd = uint128((userStakingInfo.stakedAmount * multiplier) / (MIN_MULTIPLIER * _DOWNSCALER));

        // Update the user's locking details
        userStakingInfo.lockedUntil = block.timestamp + newLockingPeriod;

        // Update the user's units
        distributionPool.increaseMemberUnits(msg.sender, unitsToAdd);
    }

    function unstake(uint256 amount) external {
        StakingInfo storage userStakingInfo = _stakingInfo[msg.sender];

        // Check if the amount is valid
        if (amount < MINIMUM_STAKE_AMOUNT) {
            revert INVALID_STAKE_AMOUNT();
        }

        // Check if user has staked tokens
        if (userStakingInfo.stakedAmount < amount) {
            revert INSUFFICIENT_STAKED_AMOUNT();
        }

        // Check locking period - user can only unstake after lock period expires
        if (userStakingInfo.lockedUntil > block.timestamp) {
            revert TOKENS_STILL_LOCKED();
        }

        // Get current units and calculate units to remove proportionally
        // This maintains the exact proportional relationship between units and staked amount
        uint128 currentUnits = distributionPool.getUnits(msg.sender);
        uint128 unitsToRemove = uint128((amount * currentUnits) / userStakingInfo.stakedAmount);

        // Update member units
        distributionPool.decreaseMemberUnits(msg.sender, unitsToRemove);

        // Update staking info
        _stakingInfo[msg.sender].stakedAmount -= amount;

        // If all tokens are unstaked, reset the staking info
        if (_stakingInfo[msg.sender].stakedAmount == 0) {
            delete _stakingInfo[msg.sender];
        }

        // Transfer staked tokens back to user
        child.transfer(msg.sender, amount);
    }

    function refreshDistributionFlow() external onlyRewardController {
        // Calculate the flowrate of the SPIRIT tokens to be distributed
        int96 flowRate = int256(SPIRIT.balanceOf(address(this)) / STREAM_OUT_DURATION).toInt96();

        SPIRIT.distributeFlow(address(this), distributionPool, flowRate);
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Calculate bonus multiplier based on locking period
     * @dev Linear function: 4 week = 10_000 (1x), 156 weeks (3 years) = 360_000 (36x)
     * @param lockingPeriod The locking period in seconds
     * @return multiplier The bonus multiplier in basis points (10_000 = 1x, 360_000 = 36x)
     */
    function calculateMultiplier(uint256 lockingPeriod) public pure returns (uint256 multiplier) {
        multiplier = MIN_MULTIPLIER + ((lockingPeriod - MINIMUM_LOCKING_PERIOD) * MULTIPLIER_RANGE) / TIME_RANGE;
    }

    function getStakingInfo(address staker) external view returns (StakingInfo memory stakingInfo) {
        stakingInfo = _stakingInfo[staker];
    }

    // INTERNAL FUNCTIONS

    function _stake(address staker, uint256 amount, uint256 lockingPeriod) internal {
        StakingInfo storage userStakingInfo = _stakingInfo[staker];

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
        uint128 units = uint128((amount * multiplier) / (MIN_MULTIPLIER * _DOWNSCALER));

        // Store staking information
        userStakingInfo.stakedAmount = amount;
        userStakingInfo.lockedUntil = block.timestamp + lockingPeriod;

        distributionPool.updateMemberUnits(staker, units);
        child.transferFrom(msg.sender, address(this), amount);
    }

    //      __  ___          ___ _____
    //     /  |/  /___  ____/ (_) __(_)__  __________
    //    / /|_/ / __ \/ __  / / /_/ / _ \/ ___/ ___/
    //   / /  / / /_/ / /_/ / / __/ /  __/ /  (__  )
    //  /_/  /_/\____/\__,_/_/_/ /_/\___/_/  /____/

    modifier onlyRewardController() {
        if (msg.sender != REWARD_CONTROLLER) {
            revert NOT_REWARD_CONTROLLER();
        }
        _;
    }

}
