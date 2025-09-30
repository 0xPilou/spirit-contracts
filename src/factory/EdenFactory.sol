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

    //      ____                          __        __    __        _____ __        __
    //     /  _/___ ___  ____ ___  __  __/ /_____ _/ /_  / /__     / ___// /_____ _/ /____  _____
    //     / // __ `__ \/ __ `__ \/ / / / __/ __ `/ __ \/ / _ \    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   _/ // / / / / / / / / / / /_/ / /_/ /_/ / /_/ / /  __/   ___/ / /_/ /_/ / /_/  __(__  )
    //  /___/_/ /_/ /_/_/ /_/ /_/\__,_/\__/\__,_/_.___/_/\___/   /____/\__/\__,_/\__/\___/____/

    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    ISuperToken public immutable SPIRIT;
    UpgradeableBeacon public immutable STAKING_POOL_BEACON;
    ISuperTokenFactory public immutable SUPER_TOKEN_FACTORY;
    IRewardController public immutable REWARD_CONTROLLER;

    uint256 public constant DEFAULT_SUPPLY = 1_000_000_000 ether;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

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

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function createChild(string memory name, string memory symbol, address artist, address agent)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (ISuperToken child, IStakingPool stakingPool)
    {
        // deploy the new child token with default 1B supply to the caller (admin)
        child = ISuperToken(_deployToken(name, symbol, DEFAULT_SUPPLY));

        // Deploy a new StakingPool contract associated to the child token
        stakingPool = IStakingPool(_deployStakingPool(address(child), artist, agent));

        // Update the reward controller configuration
        REWARD_CONTROLLER.setStakingPool(address(child), stakingPool);

        // Transfer the remaining 500M CHILD to the caller (admin)
        child.transfer(msg.sender, 500_000_000 ether);

        // FIXME : Add event emission here
    }

    function upgradeTo(address newImplementation, bytes calldata data) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC1967Utils.upgradeToAndCall(newImplementation, data);
    }

    //      ____      __                        __   ______                 __  _
    //     /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //     / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function _deployToken(string memory name, string memory symbol, uint256 supply)
        internal
        returns (address childToken)
    {
        // This salt will prevent token with the same name and symbol from being deployed twice
        bytes32 salt = keccak256(abi.encode(name, symbol));

        // Deploy the new ChildSuperToken contract
        childToken = address(new ChildSuperToken{ salt: salt }());

        // Initialize the new ChildSuperToken contract
        IChildSuperToken(childToken).initialize(SUPER_TOKEN_FACTORY, name, symbol, address(this), supply);
    }

    function _deployStakingPool(address childToken, address artist, address agent)
        internal
        returns (address stakingPool)
    {
        // This salt will prevent staking pool with the same child token from being deployed twice
        bytes32 salt = keccak256(abi.encode(childToken));

        // Deploy the new StakingPool contract
        stakingPool = address(new BeaconProxy{ salt: salt }(address(STAKING_POOL_BEACON), ""));

        // Approve the staking pool to spend the 500M CHILD (artist and agent share) from this contract
        ISuperToken(childToken).approve(address(stakingPool), 500_000_000 ether);

        // Initialize the new Locker instance
        IStakingPool(stakingPool).initialize(ISuperToken(childToken), artist, agent);
    }

}
