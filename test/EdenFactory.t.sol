// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IStakingPool } from "src/interfaces/core/IStakingPool.sol";
import { EdenTestBase } from "test/base/EdenTestBase.t.sol";

contract EdenFactoryTest is EdenTestBase {

    function setUp() public override {
        super.setUp();
    }

    function test_initialize() public view {
        assertTrue(
            _edenFactory.hasRole(_edenFactory.DEFAULT_ADMIN_ROLE(), ADMIN), "ADMIN does not have DEFAULT_ADMIN_ROLE"
        );
    }

    function test_createChild() public {
        vm.prank(ADMIN);
        (ISuperToken newChildToken, IStakingPool newStakingPool) =
            _edenFactory.createChild("New Child Token", "NEWCHILD", ARTIST, AGENT);

        assertNotEq(address(newChildToken), address(0), "Invalid child token address");
        assertNotEq(address(newStakingPool), address(0), "Invalid staking pool address");
        assertEq(newChildToken.totalSupply(), _edenFactory.DEFAULT_SUPPLY(), "Invalid minted supply");
        assertEq(address(newStakingPool.child()), address(newChildToken), "Child token mismatch");
        assertEq(address(newStakingPool.SPIRIT()), address(_spirit), "SPIRIT token mismatch");
        assertEq(address(newStakingPool.REWARD_CONTROLLER()), address(_rewardController), "Reward controller mismatch");
        assertEq(
            newStakingPool.distributionPool().getUnits(address(newStakingPool)), 1, "Distribution pool units mismatch"
        );
        assertEq(
            address(_rewardController.stakingPools(address(newChildToken))),
            address(newStakingPool),
            "Staking pool mismatch"
        );
    }

    function test_createChild_invalid_caller(address nonAdmin) public {
        vm.assume(_edenFactory.hasRole(_edenFactory.DEFAULT_ADMIN_ROLE(), nonAdmin) != true);

        vm.prank(nonAdmin);
        vm.expectRevert();
        _edenFactory.createChild("New Child Token", "NEWCHILD", ARTIST, AGENT);
    }

}
