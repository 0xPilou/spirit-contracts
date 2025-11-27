pragma solidity ^0.8.26;

/* Openzeppelin Imports */
import { AccessControl } from "@openzeppelin-v5/contracts/access/AccessControl.sol";

import { ERC1967Utils } from "@openzeppelin-v5/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { Initializable } from "@openzeppelin-v5/contracts/proxy/utils/Initializable.sol";
import { SafeCast } from "@openzeppelin-v5/contracts/utils/math/SafeCast.sol";

/* Superfluid Imports */
import { SuperTokenV1Library } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/* Local Imports */
import { IRewardController } from "src/interfaces/core/IRewardController.sol";
import { IStakingPool } from "src/interfaces/core/IStakingPool.sol";

/* Library Settings */
using SuperTokenV1Library for ISuperToken;
using SafeCast for int256;

/**
 * @title RewardController
 * @notice RewardController contract
 * @dev This contract is used to distribute SPIRIT rewards to staking pools
 */
contract RewardController is IRewardController, AccessControl, Initializable {

    //      ____                          __        __    __        _____ __        __
    //     /  _/___ ___  ____ ___  __  __/ /_____ _/ /_  / /__     / ___// /_____ _/ /____  _____
    //     / // __ `__ \/ __ `__ \/ / / / __/ __ `/ __ \/ / _ \    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   _/ // / / / / / / / / / / /_/ / /_/ /_/ / /_/ / /  __/   ___/ / /_/ /_/ / /_/  __(__  )
    //  /___/_/ /_/ /_/_/ /_/ /_/\__,_/\__/\__,_/_.___/_/\___/   /____/\__/\__,_/\__/\___/____/

    /// @notice Role identifier for the factory contract
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    /// @notice Role identifier for the distributor
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    /// @notice The SPIRIT SuperToken distributed as rewards
    ISuperToken public immutable SPIRIT;

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @notice Mapping of child addresses to their associated staking pool contracts
    mapping(address child => IStakingPool stakingPool) public stakingPools;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice RewardController contract constructor
     * @param _spirit The SPIRIT SuperToken distributed as rewards
     */
    constructor(ISuperToken _spirit) {
        // Prevent initialization of implementationcontract
        _disableInitializers();

        // Set the SPIRIT SuperToken distributed as rewards
        SPIRIT = _spirit;
    }

    /**
     * @notice Initializes the RewardController contract
     * @param admin The address to grant the DEFAULT_ADMIN_ROLE and DISTRIBUTOR_ROLE
     */
    function initialize(address admin) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DISTRIBUTOR_ROLE, admin);
    }

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /// @inheritdoc IRewardController
    function setStakingPool(address child, IStakingPool stakingPool) external onlyRole(FACTORY_ROLE) {
        // Input validation
        if (child == address(0)) {
            revert INVALID_CHILD();
        }
        if (stakingPools[child] != IStakingPool(address(0))) {
            revert STAKING_POOL_ALREADY_SET();
        }

        // Sets the staking pool associated to the child
        stakingPools[child] = stakingPool;
    }

    /// @inheritdoc IRewardController
    function distributeRewards(address child, uint256 amount) external onlyRole(DISTRIBUTOR_ROLE) {
        // Gets the staking pool associated to the child
        IStakingPool stakingPool = stakingPools[child];

        // Input validation
        if (stakingPool == IStakingPool(address(0))) {
            revert STAKING_POOL_NOT_FOUND();
        }
        if (amount == 0) {
            revert INVALID_AMOUNT();
        }

        // Transfer SPIRIT from the distributor to the staking pool contract
        SPIRIT.transferFrom(msg.sender, address(stakingPool), amount);

        // Refresh the distribution flow
        stakingPool.refreshDistributionFlow();
    }

    /// @inheritdoc IRewardController
    function upgradeTo(address newImplementation, bytes calldata data) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC1967Utils.upgradeToAndCall(newImplementation, data);
    }

}
