pragma solidity ^0.8.26;

/* Local Imports */
import { IStakingPool } from "src/interfaces/core/IStakingPool.sol";

/**
 * @title IRewardController
 * @notice IRewardController interface
 * @dev This contract is used to distribute SPIRIT rewards to staking pools
 */
interface IRewardController {

    //     ______           __                     ______
    //    / ____/_  _______/ /_____  ____ ___     / ____/_____________  __________
    //   / /   / / / / ___/ __/ __ \/ __ `__ \   / __/ / ___/ ___/ __ \/ ___/ ___/
    //  / /___/ /_/ (__  ) /_/ /_/ / / / / / /  / /___/ /  / /  / /_/ / /  (__  )
    //  \____/\__,_/____/\__/\____/_/ /_/ /_/  /_____/_/  /_/   \____/_/  /____/

    /// @notice Thrown when a staking pool is already associated with the given child address.
    error STAKING_POOL_ALREADY_SET();

    /// @notice Thrown when a staking pool is not found for the given child address.
    error STAKING_POOL_NOT_FOUND();

    /// @notice Thrown when the provided child address is invalid (e.g., zero address).
    error INVALID_CHILD();

    /// @notice Thrown when the reward amount provided is invalid (e.g., zero value).
    error INVALID_AMOUNT();

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Sets the staking pool associated with a specific child address.
     * @dev Only callable by an address with the FACTORY_ROLE.
     * @param child The child address for which to set the staking pool
     * @param stakingPool The staking pool contract address
     */
    function setStakingPool(address child, IStakingPool stakingPool) external;

    /**
     * @notice Distributes rewards to a specific staking pool.
     * @dev Only callable by an address with the DISTRIBUTOR_ROLE.
     * @param child The child address for which to distribute rewards
     * @param amount The amount of rewards to distribute
     */
    function distributeRewards(address child, uint256 amount) external;

    /**
     * @notice Upgrades the RewardController contract to a new implementation.
     * @dev Only callable by an address with the DEFAULT_ADMIN_ROLE.
     * @param newImplementation The new implementation contract address
     * @param data The data to pass to the new implementation
     */
    function upgradeTo(address newImplementation, bytes calldata data) external;

}
