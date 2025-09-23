// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { EdenTestBase } from "test/base/EdenTestBase.t.sol";

contract RewardControllerTest is EdenTestBase {

    function setUp() public override {
        super.setUp();
    }

    function test_initialize() public view {
        assertTrue(
            _rewardController.hasRole(_rewardController.DEFAULT_ADMIN_ROLE(), ADMIN),
            "ADMIN does not have DEFAULT_ADMIN_ROLE"
        );
        assertTrue(
            _rewardController.hasRole(_rewardController.DISTRIBUTOR_ROLE(), ADMIN),
            "ADMIN does not have DISTRIBUTOR_ROLE"
        );
    }

    function test_setStakingPool() public { }
    function test_setStakingPool_invalid_caller() public { }
    function test_setStakingPool_invalid_child() public { }
    function test_setStakingPool_staking_pool_already_set() public { }
    function test_distributeRewards() public { }
    function test_distributeRewards_invalid_caller() public { }
    function test_distributeRewards_staking_pool_not_found() public { }
    function test_distributeRewards_invalid_amount() public { }

}
