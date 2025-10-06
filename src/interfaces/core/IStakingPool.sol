pragma solidity ^0.8.26;

import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { ISuperfluidPool } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

interface IStakingPool {

    //      ____        __        __
    //     / __ \____ _/ /_____ _/ /___  ______  ___  _____
    //    / / / / __ `/ __/ __ `/ __/ / / / __ \/ _ \/ ___/
    //   / /_/ / /_/ / /_/ /_/ / /_/ /_/ / /_/ /  __(__  )
    //  /_____/\__,_/\__/\__,_/\__/\__, / .___/\___/____/
    //                            /____/_/

    struct StakingInfo {
        uint256 stakedAmount;
        uint256 lockedUntil;
    }

    //     ______           __                     ______
    //    / ____/_  _______/ /_____  ____ ___     / ____/_____________  __________
    //   / /   / / / / ___/ __/ __ \/ __ `__ \   / __/ / ___/ ___/ __ \/ ___/ ___/
    //  / /___/ /_/ (__  ) /_/ /_/ / / / / / /  / /___/ /  / /  / /_/ / /  (__  )
    //  \____/\__,_/____/\__/\____/_/ /_/ /_/  /_____/_/  /_/   \____/_/  /____/

    error INVALID_LOCKING_PERIOD();
    error NOT_STAKED_YET();
    error ALREADY_STAKED();
    error LOCK_NOT_EXPIRED();
    error INVALID_STAKE_AMOUNT();
    error NOT_REWARD_CONTROLLER();
    error INSUFFICIENT_STAKED_AMOUNT();
    error TOKENS_STILL_LOCKED();

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice StakingPool contract initializer
     * @param _child Child token
     * @param artist Artist address
     * @param agent Agent address
     */
    function initialize(ISuperToken _child, address artist, address agent) external;

    /**
     * @notice Stake tokens
     * @param amount Amount of tokens to stake
     * @param lockingPeriod Locking period
     */
    function stake(uint256 amount, uint256 lockingPeriod) external;

    /**
     * @notice Increase stake
     * @param amount Amount of tokens to increase stake
     */
    function increaseStake(uint256 amount) external;

    /**
     * @notice Extends locking period
     * @param newLockingPeriod New locking period
     */
    function extendLockingPeriod(uint256 newLockingPeriod) external;

    /**
     * @notice Unstake tokens
     * @param amount Amount of tokens to unstake
     */
    function unstake(uint256 amount) external;

    /**
     * @notice Refreshes distribution flow
     */
    function refreshDistributionFlow() external;

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Calculate bonus multiplier based on locking period
     * @dev Linear function: 1 week = 10_000 (1x), 156 weeks (3 years) = 360_000 (36x)
     * @param lockingPeriod The locking period in seconds
     * @return multiplier The bonus multiplier in basis points (10_000 = 1x, 360_000 = 36x)
     */
    function calculateMultiplier(uint256 lockingPeriod) external pure returns (uint256 multiplier);

    /**
     * @notice Gets staking info
     * @param staker Staker address
     * @return stakingInfo Staking info
     */
    function getStakingInfo(address staker) external view returns (StakingInfo memory stakingInfo);

    /**
     * @notice Gets SPIRIT token
     * @return SPIRIT SPIRIT token
     */
    function SPIRIT() external view returns (ISuperToken);

    /**
     * @notice Gets child token
     * @return child Child token
     */
    function child() external view returns (ISuperToken);

    /**
     * @notice Gets reward controller
     * @return REWARD_CONTROLLER Reward controller
     */
    function REWARD_CONTROLLER() external view returns (address);

    /**
     * @notice Gets distribution pool
     * @return distributionPool Distribution pool
     */
    function distributionPool() external view returns (ISuperfluidPool);

    /**
     * @notice Gets stream out duration
     * @return STREAM_OUT_DURATION Stream out duration
     */
    function STREAM_OUT_DURATION() external view returns (uint256);

    /**
     * @notice Gets minimum locking period
     * @return MINIMUM_LOCKING_PERIOD Minimum locking period
     */
    function MINIMUM_LOCKING_PERIOD() external view returns (uint256);

    /**
     * @notice Gets maximum locking period
     * @return MAXIMUM_LOCKING_PERIOD Maximum locking period
     */
    function MAXIMUM_LOCKING_PERIOD() external view returns (uint256);

    /**
     * @notice Gets minimum stake amount
     * @return MINIMUM_STAKE_AMOUNT Minimum stake amount
     */
    function MINIMUM_STAKE_AMOUNT() external view returns (uint256);

    /**
     * @notice Gets minimum multiplier
     * @return MIN_MULTIPLIER Minimum multiplier
     */
    function MIN_MULTIPLIER() external view returns (uint256);

    /**
     * @notice Gets maximum multiplier
     * @return MAX_MULTIPLIER Maximum multiplier
     */
    function MAX_MULTIPLIER() external view returns (uint256);

    /**
     * @notice Gets multiplier range
     * @return MULTIPLIER_RANGE Multiplier range
     */
    function MULTIPLIER_RANGE() external view returns (uint256);

    /**
     * @notice Gets time range
     * @return TIME_RANGE Time range
     */
    function TIME_RANGE() external view returns (uint256);

}
