pragma solidity ^0.8.26;

/* Openzeppelin Imports */
import { AccessControl } from "@openzeppelin-v5/contracts/access/AccessControl.sol";
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

contract RewardController is IRewardController, AccessControl {

    // STATES
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    ISuperToken public immutable SPIRIT;

    mapping(address child => IStakingPool stakingPool) public stakingPools;

    // CONSTRUCTOR
    constructor(address admin, ISuperToken _spirit) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DISTRIBUTOR_ROLE, admin);

        SPIRIT = _spirit;
    }

    // EXTERNAL FUNCTIONS
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

}
