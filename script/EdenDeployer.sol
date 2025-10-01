// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { ERC1967Proxy } from "@openzeppelin-v5/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UpgradeableBeacon } from "@openzeppelin-v5/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";

import { ISuperTokenFactory } from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperTokenFactory.sol";

import { NetworkConfig } from "script/config/NetworkConfig.sol";
import { RewardController } from "src/core/RewardController.sol";
import { StakingPool } from "src/core/StakingPool.sol";
import { EdenFactory } from "src/factory/EdenFactory.sol";
import { IRewardController } from "src/interfaces/core/IRewardController.sol";
import { ISpiritToken } from "src/interfaces/token/ISpiritToken.sol";
import { SpiritToken } from "src/token/SpiritToken.sol";

library EdenDeployer {

    struct EdenDeploymentResult {
        address spirit;
        address rewardControllerLogic;
        address rewardControllerProxy;
        address stakingPoolLogic;
        address stakingPoolBeacon;
        address edenFactoryLogic;
        address edenFactoryProxy;
    }

    function deployAll(NetworkConfig.EdenDeploymentConfig memory config, address deployer)
        internal
        returns (EdenDeploymentResult memory results)
    {
        // Contracts Deployment

        // Deploy the Spirit Token Contract
        results = _deploySpiritToken(config);

        // Deploy the Infrastructure Contracts
        results = _deployInfrastructure(config, results);

        // Contracts Configuration
        RewardController rc = RewardController(results.rewardControllerProxy);
        rc.grantRole(rc.FACTORY_ROLE(), address(results.edenFactoryProxy));
        rc.revokeRole(rc.DEFAULT_ADMIN_ROLE(), deployer);
    }

    function _deploySpiritToken(NetworkConfig.EdenDeploymentConfig memory config)
        internal
        returns (EdenDeploymentResult memory results)
    {
        results.spirit = address(new SpiritToken());

        // Initialize the new SpiritToken contract
        ISpiritToken(results.spirit).initialize(
            ISuperTokenFactory(config.superTokenFactory),
            config.spiritTokenName,
            config.spiritTokenSymbol,
            config.treasury,
            config.spiritTokenSupply
        );
    }

    function _deployInfrastructure(
        NetworkConfig.EdenDeploymentConfig memory config,
        EdenDeploymentResult memory results
    ) internal returns (EdenDeploymentResult memory) {
        // Deploy the Reward Controller contract
        RewardController rewardControllerLogic = new RewardController(ISuperToken(results.spirit));
        ERC1967Proxy rewardControllerProxy = new ERC1967Proxy(
            address(rewardControllerLogic), abi.encodeWithSelector(RewardController.initialize.selector, config.admin)
        );

        // Deploy the Staking Pool Beacon contract
        address stakingPoolLogicAddress =
            address(new StakingPool(ISuperToken(results.spirit), address(rewardControllerProxy)));
        UpgradeableBeacon stakingPoolBeacon = new UpgradeableBeacon(stakingPoolLogicAddress, config.admin);

        // Deploy the Eden Factory contract
        EdenFactory edenFactoryLogic = new EdenFactory(
            address(stakingPoolBeacon),
            IRewardController(address(rewardControllerProxy)),
            ISuperTokenFactory(config.superTokenFactory)
        );
        ERC1967Proxy edenFactoryProxy = new ERC1967Proxy(
            address(edenFactoryLogic), abi.encodeWithSelector(EdenFactory.initialize.selector, config.admin)
        );

        results.rewardControllerLogic = address(rewardControllerLogic);
        results.rewardControllerProxy = address(rewardControllerProxy);
        results.stakingPoolBeacon = address(stakingPoolBeacon);
        results.stakingPoolLogic = address(stakingPoolLogicAddress);
        results.edenFactoryLogic = address(edenFactoryLogic);
        results.edenFactoryProxy = address(edenFactoryProxy);

        return results;
    }

}
