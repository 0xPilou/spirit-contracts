pragma solidity ^0.8.26;

/* Openzeppelin Imports */
import { AccessControl } from "@openzeppelin-v5/contracts/access/AccessControl.sol";
import { ERC1967Utils } from "@openzeppelin-v5/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { BeaconProxy } from "@openzeppelin-v5/contracts/proxy/beacon/BeaconProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin-v5/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { Initializable } from "@openzeppelin-v5/contracts/proxy/utils/Initializable.sol";

/* Superfluid Imports */
import { ISuperTokenFactory } from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperTokenFactory.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/* Local Imports */
import { IRewardController } from "src/interfaces/core/IRewardController.sol";
import { IStakingPool } from "src/interfaces/core/IStakingPool.sol";
import { IEdenFactory } from "src/interfaces/factory/IEdenFactory.sol";
import { IChildSuperToken } from "src/interfaces/token/IChildSuperToken.sol";
import { ChildSuperToken } from "src/token/ChildSuperToken.sol";

contract EdenFactory is IEdenFactory, Initializable, AccessControl {

    UpgradeableBeacon public immutable STAKING_POOL_BEACON;
    ISuperTokenFactory public immutable SUPER_TOKEN_FACTORY;
    IRewardController public immutable REWARD_CONTROLLER;

    uint256 public constant DEFAULT_SUPPLY = 1_000_000_000 ether;

    constructor(
        address _stakingPoolBeacon,
        IRewardController _rewardController,
        ISuperTokenFactory _superTokenFactory
    ) {
        STAKING_POOL_BEACON = UpgradeableBeacon(_stakingPoolBeacon);
        REWARD_CONTROLLER = _rewardController;
        SUPER_TOKEN_FACTORY = _superTokenFactory;
    }

    function initialize(address admin) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function createChild(string memory name, string memory symbol)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (ISuperToken child, IStakingPool stakingPool)
    {
        // deploy the new child token with default 1B supply to the caller (admin)
        child = ISuperToken(_deployToken(name, symbol, DEFAULT_SUPPLY, msg.sender));

        // Deploy a new StakingPool contract associated to the child token
        stakingPool = IStakingPool(_deployStakingPool(address(child)));

        // Update the reward controller configuration
        REWARD_CONTROLLER.setStakingPool(address(child), stakingPool);

        // FIXME : Add event emission here
    }

    function upgradeTo(address newImplementation, bytes calldata data) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC1967Utils.upgradeToAndCall(newImplementation, data);
    }

    /// INTERNAL
    function _deployToken(string memory name, string memory symbol, uint256 supply, address recipient)
        internal
        returns (address childToken)
    {
        // This salt will prevent token with the same name and symbol from being deployed twice
        bytes32 salt = keccak256(abi.encode(name, symbol));

        // Deploy the new ChildSuperToken contract
        childToken = address(new ChildSuperToken{ salt: salt }());

        // Initialize the new ChildSuperToken contract
        IChildSuperToken(childToken).initialize(SUPER_TOKEN_FACTORY, name, symbol, recipient, supply);
    }

    function _deployStakingPool(address childToken) internal returns (address stakingPool) {
        // This salt will prevent staking pool with the same child token from being deployed twice
        bytes32 salt = keccak256(abi.encode(childToken));

        // Deploy the new StakingPool contract
        stakingPool = address(
            new BeaconProxy{ salt: salt }(
                address(STAKING_POOL_BEACON),
                abi.encodeWithSelector(IStakingPool.initialize.selector, ISuperToken(childToken))
            )
        );
    }

}
