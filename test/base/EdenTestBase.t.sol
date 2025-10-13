// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";

import { VestingSchedulerV3 } from "@superfluid-finance/automation-contracts/scheduler/contracts/VestingSchedulerV3.sol";
import { SuperTokenV1Library } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import { ERC1820RegistryCompiled } from
    "@superfluid-finance/ethereum-contracts/contracts/libs/ERC1820RegistryCompiled.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/superfluid/SuperToken.sol";
import { SuperfluidFrameworkDeployer } from
    "@superfluid-finance/ethereum-contracts/contracts/utils/SuperfluidFrameworkDeployer.t.sol";

/* Local Imports */
import { EdenDeployer } from "script/EdenDeployer.sol";
import { NetworkConfig } from "script/config/NetworkConfig.sol";

import { RewardController } from "src/core/RewardController.sol";
import { EdenFactory } from "src/factory/EdenFactory.sol";
import { UniswapDeployer } from "test/utils/UniswapDeployer.sol";

contract EdenTestBase is UniswapDeployer {

    using SuperTokenV1Library for ISuperToken;

    // Contracts under test
    EdenFactory internal _edenFactory;
    RewardController internal _rewardController;

    ISuperToken internal _spirit;

    SuperfluidFrameworkDeployer internal _deployer;
    SuperfluidFrameworkDeployer.Framework internal _sf;

    address internal immutable DEPLOYER = makeAddr("DEPLOYER");
    address internal immutable TREASURY = makeAddr("TREASURY");
    address internal immutable ADMIN = makeAddr("ADMIN");
    address internal immutable ALICE = makeAddr("ALICE");
    address internal immutable ARTIST = makeAddr("ARTIST");
    address internal immutable AGENT = makeAddr("AGENT");

    function setUp() public virtual override {
        // Superfluid Protocol Deployment Start
        vm.etch(ERC1820RegistryCompiled.at, ERC1820RegistryCompiled.bin);
        _deployer = new SuperfluidFrameworkDeployer();
        _deployer.deployTestFramework();
        _sf = _deployer.getFramework();

        // Superfluid Protocol Deployment End

        UniswapDeployer.setUp();

        NetworkConfig.EdenDeploymentConfig memory config = NetworkConfig.getLocalConfig();

        config.admin = ADMIN;
        config.distributor = ADMIN;
        config.treasury = TREASURY;
        config.superTokenFactory = address(_sf.superTokenFactory);
        config.positionManager = address(positionManager);
        config.poolManager = address(manager);
        config.permit2 = address(permit2);
        config.vestingScheduler = address(new VestingSchedulerV3(_sf.host));

        // Deploy the contracts under test
        vm.startPrank(DEPLOYER);
        EdenDeployer.EdenDeploymentResult memory result = EdenDeployer.deployAll(config, DEPLOYER);
        vm.stopPrank();

        _edenFactory = EdenFactory(result.edenFactoryProxy);
        _rewardController = RewardController(result.rewardControllerProxy);
        _spirit = ISuperToken(result.spirit);
    }

    function dealSuperToken(address from, address to, ISuperToken token, uint256 amount) internal {
        vm.startPrank(from);
        token.transfer(to, amount);
        vm.stopPrank();
    }

}
