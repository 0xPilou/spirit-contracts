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

    function initialize(ISuperToken _child, address artist, address agent) external;

    function stake(uint256 amount, uint256 lockingPeriod) external;

    function increaseStake(uint256 amount) external;

    function extendLockingPeriod(uint256 newLockingPeriod) external;

    function calculateMultiplier(uint256 lockingPeriod) external pure returns (uint256 multiplier);

    function unstake(uint256 amount) external;

    function refreshDistributionFlow() external;

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function getStakingInfo(address staker) external view returns (StakingInfo memory stakingInfo);
    function SPIRIT() external view returns (ISuperToken);
    function child() external view returns (ISuperToken);
    function REWARD_CONTROLLER() external view returns (address);
    function distributionPool() external view returns (ISuperfluidPool);
    function STREAM_OUT_DURATION() external view returns (uint256);
    function MINIMUM_LOCKING_PERIOD() external view returns (uint256);
    function MAXIMUM_LOCKING_PERIOD() external view returns (uint256);
    function MINIMUM_STAKE_AMOUNT() external view returns (uint256);
    function MIN_MULTIPLIER() external view returns (uint256);
    function MAX_MULTIPLIER() external view returns (uint256);
    function MULTIPLIER_RANGE() external view returns (uint256);
    function TIME_RANGE() external view returns (uint256);

}
