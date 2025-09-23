// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";

import { ERC1967Proxy } from "@openzeppelin-v5/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { UpgradeableBeacon } from "@openzeppelin-v5/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { SuperTokenV1Library } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import { ERC1820RegistryCompiled } from
    "@superfluid-finance/ethereum-contracts/contracts/libs/ERC1820RegistryCompiled.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/superfluid/SuperToken.sol";
import { SuperfluidFrameworkDeployer } from
    "@superfluid-finance/ethereum-contracts/contracts/utils/SuperfluidFrameworkDeployer.t.sol";

/* Local Imports */
import { RewardController } from "src/core/RewardController.sol";
import { StakingPool } from "src/core/StakingPool.sol";
import { EdenFactory } from "src/factory/EdenFactory.sol";

contract EdenTestBase is Test {

    using SuperTokenV1Library for ISuperToken;

    // Contracts under test
    EdenFactory internal _edenFactory;
    RewardController internal _rewardController;

    ISuperToken internal _spirit;

    SuperfluidFrameworkDeployer internal _deployer;
    SuperfluidFrameworkDeployer.Framework internal _sf;

    address internal immutable TREASURY = makeAddr("TREASURY");
    address internal immutable ADMIN = makeAddr("ADMIN");
    address internal immutable ALICE = makeAddr("ALICE");
    address internal immutable BOB = makeAddr("BOB");
    address internal immutable CAROL = makeAddr("CAROL");

    function setUp() public virtual {
        // Superfluid Protocol Deployment Start
        vm.etch(ERC1820RegistryCompiled.at, ERC1820RegistryCompiled.bin);
        _deployer = new SuperfluidFrameworkDeployer();
        _deployer.deployTestFramework();
        _sf = _deployer.getFramework();
        // Superfluid Protocol Deployment End

        /// FIXME : add UNISWAP V4 Deployment here

        // Deploy the contracts under test
        _deployAll();
    }

    function _deployAll() internal {
        // Contracts Deployment

        // Deploy the Spirit Token Contract
        vm.prank(TREASURY);
        _spirit = _deployer.deployPureSuperToken("Spirit Token", "SPIRIT", 1_000_000_000 ether);

        // Deploy the Reward Controller contract
        RewardController rewardControllerLogic = new RewardController(_spirit);
        ERC1967Proxy rewardControllerProxy = new ERC1967Proxy(
            address(rewardControllerLogic), abi.encodeWithSelector(RewardController.initialize.selector, ADMIN)
        );

        _rewardController = RewardController(address(rewardControllerProxy));

        // Deploy the Staking Pool Beacon contract
        address stakingPoolLogicAddress = address(new StakingPool(_spirit, address(_rewardController)));
        UpgradeableBeacon stakingPoolBeacon = new UpgradeableBeacon(stakingPoolLogicAddress, ADMIN);

        // Deploy the Eden Factory contract
        EdenFactory edenFactoryLogic =
            new EdenFactory(address(stakingPoolBeacon), _rewardController, _sf.superTokenFactory);
        ERC1967Proxy edenFactoryProxy =
            new ERC1967Proxy(address(edenFactoryLogic), abi.encodeWithSelector(EdenFactory.initialize.selector, ADMIN));
        _edenFactory = EdenFactory(address(edenFactoryProxy));

        // Contracts Configuration

        // Grant the FACTORY_ROLE to the Eden Factory
        vm.startPrank(ADMIN);
        _rewardController.grantRole(_rewardController.FACTORY_ROLE(), address(_edenFactory));
        vm.stopPrank();
    }

    function dealSuperToken(address from, address to, ISuperToken token, uint256 amount) internal {
        vm.startPrank(from);
        token.transfer(to, amount);
        vm.stopPrank();
    }

}
