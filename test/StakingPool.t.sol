// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/superfluid/SuperToken.sol";

import { IStakingPool } from "src/interfaces/core/IStakingPool.sol";
import { EdenTestBase } from "test/base/EdenTestBase.t.sol";

contract StakingPoolTest is EdenTestBase {

    // Contract under test
    IStakingPool internal _stakingPool;
    ISuperToken internal _childToken;

    uint256 internal constant _TOKEN_SUPPLY = 1_000_000_000 ether;

    function setUp() public override {
        super.setUp();

        // Deploy and initialize the StakingPool
        vm.prank(ADMIN);
        (_childToken, _stakingPool) = _edenFactory.createChild("Child Token", "CHILD");
    }

    function test_initialize() public view {
        assertEq(address(_stakingPool.SPIRIT()), address(_spirit), "SPIRIT token mismatch");
        assertEq(address(_stakingPool.child()), address(_childToken), "Child token mismatch");
        assertNotEq(address(_stakingPool.distributionPool()), address(0), "Distribution pool not deployed");
        assertEq(_stakingPool.REWARD_CONTROLLER(), address(_rewardController), "Reward controller mismatch");
        assertEq(_stakingPool.distributionPool().getUnits(address(_stakingPool)), 1, "Pool units mismatch");
    }

    function test_stake() public { }
    function test_stake_already_staked() public { }
    function test_stake_invalid_stake_amount() public { }
    function test_stake_invalid_locking_period() public { }
    function test_increaseStake() public { }
    function test_increaseStake_not_staked_yet() public { }
    function test_increaseStake_invalid_stake_amount() public { }
    function test_unstake() public { }
    function test_refreshDistributionFlow() public { }

}
