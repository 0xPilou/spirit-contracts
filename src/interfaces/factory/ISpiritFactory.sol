pragma solidity ^0.8.26;

/* Superfluid Imports */
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/* Local Imports */
import { IStakingPool } from "src/interfaces/core/IStakingPool.sol";

/**
 * @title ISpiritFactory
 * @notice ISpiritFactory interface
 * @dev This contract is used to create child tokens and staking pools
 */
interface ISpiritFactory {

    //      ______                 __
    //     / ____/   _____  ____  / /______
    //    / __/ | | / / _ \/ __ \/ __/ ___/
    //   / /___ | |/ /  __/ / / / /_(__  )
    //  /_____/ |___/\___/_/ /_/\__/____/

    /// @notice Event emitted when a child token is created
    event ChildTokenCreated(
        address indexed child, address indexed stakingPool, address artist, address agent, bytes32 merkleRoot
    );

    //     ______           __                     ______
    //    / ____/_  _______/ /_____  ____ ___     / ____/_____________  __________
    //   / /   / / / / ___/ __/ __ \/ __ `__ \   / __/ / ___/ ___/ __ \/ ___/ ___/
    //  / /___/ /_/ (__  ) /_/ /_/ / / / / / /  / /___/ /  / /  / /_/ / /  (__  )
    //  \____/\__,_/____/\__/\____/_/ /_/ /_/  /_____/_/  /_/   \____/_/  /____/

    /// @notice Thrown when the special allocation is greater than the default liquidity supply
    error INVALID_SPECIAL_ALLOCATION();

    /// @notice Thrown when the Uniswap V4 pool initialization fails or has been initialized before
    error POOL_INITIALIZATION_FAILED();

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Creates a child token and staking pool
     * @dev This function is only callable by the DEFAULT_ADMIN_ROLE
     * @param name The name of the child token
     * @param symbol The symbol of the child token
     * @param artist The address of the artist
     * @param agent The address of the agent
     * @param merkleRoot The merkle root containing the airdrop allocations
     * @param initialSqrtPriceX96 The initial sqrt price X96 for the Uniswap V4 pool SPIRIT/CHILD
     * @return child The address of the child token
     * @return stakingPool The address of the staking pool
     */
    function createChild(
        string memory name,
        string memory symbol,
        address artist,
        address agent,
        bytes32 merkleRoot,
        uint160 initialSqrtPriceX96
    ) external returns (ISuperToken child, IStakingPool stakingPool);

    /**
     * @notice Creates a child token and staking pool
     * @dev This function is only callable by the DEFAULT_ADMIN_ROLE
     * @param name The name of the child token
     * @param symbol The symbol of the child token
     * @param artist The address of the artist
     * @param agent The address of the agent
     * @param specialAllocation The amount of tokens reserved for the special allocation
     * @param merkleRoot The merkle root containing the airdrop allocations
     * @param initialSqrtPriceX96 The initial sqrt price X96 for the Uniswap V4 pool SPIRIT/CHILD
     * @return child The address of the child token
     * @return stakingPool The address of the staking pool
     */
    function createChild(
        string memory name,
        string memory symbol,
        address artist,
        address agent,
        uint256 specialAllocation,
        bytes32 merkleRoot,
        uint160 initialSqrtPriceX96
    ) external returns (ISuperToken child, IStakingPool stakingPool);

    /**
     * @notice Upgrades the SpiritFactory contract to a new implementation
     * @dev This function is only callable by the DEFAULT_ADMIN_ROLE
     * @param newImplementation The address of the new implementation
     * @param data The data to pass to the new implementation
     */
    function upgradeTo(address newImplementation, bytes calldata data) external;

}
