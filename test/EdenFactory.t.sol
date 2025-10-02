// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IERC721 } from "@openzeppelin-v5/contracts/token/ERC721/IERC721.sol";
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

        // State settings assertions
        assertNotEq(address(newChildToken), address(0), "Invalid child token address");
        assertNotEq(address(newStakingPool), address(0), "Invalid staking pool address");
        assertEq(address(newStakingPool.child()), address(newChildToken), "Child token mismatch");
        assertEq(address(newStakingPool.SPIRIT()), address(_spirit), "SPIRIT token mismatch");
        assertEq(address(newStakingPool.REWARD_CONTROLLER()), address(_rewardController), "Reward controller mismatch");
        assertEq(
            address(_rewardController.stakingPools(address(newChildToken))),
            address(newStakingPool),
            "Staking pool mismatch"
        );

        // Token Supply Assertions
        assertEq(newChildToken.totalSupply(), _edenFactory.DEFAULT_SUPPLY(), "Invalid minted supply");
        assertEq(newChildToken.balanceOf(ARTIST), 0, "Artist should not have floating CHILD tokens");
        assertEq(newChildToken.balanceOf(AGENT), 0, "Agent should not have floating CHILD tokens");
        assertEq(
            newChildToken.balanceOf(address(newStakingPool)),
            500_000_000 ether,
            "Staking Pool should have 500M CHILD tokens (ARTIST and AGENT shares)"
        );

        assertEq(
            newChildToken.balanceOf(address(manager)),
            475_000_000 ether,
            "UniswapV4 Pool Manager should have 475M CHILD tokens (Liquidity)"
        );

        assertEq(
            newChildToken.balanceOf(address(ADMIN)),
            25_000_000 ether,
            "Admin should have 500M CHILD tokens (ADMIN share)"
        );

        assertEq(
            IERC721(address(positionManager)).balanceOf(address(ADMIN)), 1, "ADMIN should own 1 UniswapV4 Position NFT"
        );

        // GDA Settings Assertions
        assertEq(
            newStakingPool.distributionPool().getUnits(address(newStakingPool)), 1, "Distribution pool units mismatch"
        );
        assertEq(
            newStakingPool.distributionPool().getUnits(address(ARTIST)),
            newStakingPool.calculateMultiplier(52 weeks) * 250_000_000 / newStakingPool.MIN_MULTIPLIER(),
            "ARTIST should have 250M CHILD tokens locked for 12 months worth of units"
        );
        assertEq(
            newStakingPool.distributionPool().getUnits(address(AGENT)),
            newStakingPool.calculateMultiplier(52 weeks) * 250_000_000 / newStakingPool.MIN_MULTIPLIER(),
            "AGENT should have 250M CHILD tokens locked for 12 months worth of units"
        );
    }

    function test_createChild_invalid_caller(address nonAdmin) public {
        vm.assume(_edenFactory.hasRole(_edenFactory.DEFAULT_ADMIN_ROLE(), nonAdmin) != true);

        vm.prank(nonAdmin);
        vm.expectRevert();
        _edenFactory.createChild("New Child Token", "NEWCHILD", ARTIST, AGENT);
    }

}
