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

    function test_stake(uint256 amountToStake, uint256 lockingPeriod) public {
        amountToStake = bound(amountToStake, _stakingPool.MINIMUM_STAKE_AMOUNT(), _TOKEN_SUPPLY);
        lockingPeriod =
            bound(lockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        _stake(ALICE, amountToStake, lockingPeriod);
    }

    function test_stake_already_staked(
        uint256 initialAmountToStake,
        uint256 additionalAmountToStake,
        uint256 lockingPeriod
    ) public {
        initialAmountToStake = bound(initialAmountToStake, _stakingPool.MINIMUM_STAKE_AMOUNT(), _TOKEN_SUPPLY / 2);
        additionalAmountToStake = bound(additionalAmountToStake, _stakingPool.MINIMUM_STAKE_AMOUNT(), _TOKEN_SUPPLY / 2);

        lockingPeriod =
            bound(lockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        _stake(ALICE, initialAmountToStake, lockingPeriod);
        _stake_should_revert(
            ALICE, additionalAmountToStake, lockingPeriod, abi.encodeWithSelector(IStakingPool.ALREADY_STAKED.selector)
        );
    }

    function test_stake_invalid_stake_amount(uint256 invalidAmountToStake, uint256 lockingPeriod) public {
        invalidAmountToStake = bound(invalidAmountToStake, 1, _stakingPool.MINIMUM_STAKE_AMOUNT() - 1);
        lockingPeriod =
            bound(lockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        _stake_should_revert(
            ALICE,
            invalidAmountToStake,
            lockingPeriod,
            abi.encodeWithSelector(IStakingPool.INVALID_STAKE_AMOUNT.selector)
        );
    }

    function test_stake_invalid_locking_period_too_short(uint256 amountToStake, uint256 invalidLockingPeriod) public {
        amountToStake = bound(amountToStake, _stakingPool.MINIMUM_STAKE_AMOUNT(), _TOKEN_SUPPLY);
        invalidLockingPeriod = bound(invalidLockingPeriod, 0, _stakingPool.MINIMUM_LOCKING_PERIOD() - 1);

        _stake_should_revert(
            ALICE,
            amountToStake,
            invalidLockingPeriod,
            abi.encodeWithSelector(IStakingPool.INVALID_LOCKING_PERIOD.selector)
        );
    }

    function test_stake_invalid_locking_period_too_long(uint256 amountToStake, uint256 invalidLockingPeriod) public {
        amountToStake = bound(amountToStake, _stakingPool.MINIMUM_STAKE_AMOUNT(), _TOKEN_SUPPLY);

        invalidLockingPeriod =
            bound(invalidLockingPeriod, _stakingPool.MAXIMUM_LOCKING_PERIOD() + 1, uint256(type(uint256).max));

        _stake_should_revert(
            ALICE,
            amountToStake,
            invalidLockingPeriod,
            abi.encodeWithSelector(IStakingPool.INVALID_LOCKING_PERIOD.selector)
        );
    }

    function test_increaseStake() public { }
    function test_increaseStake_not_staked_yet() public { }
    function test_increaseStake_invalid_stake_amount() public { }
    function test_unstake() public { }
    function test_unstake_insufficient_staked_amount() public { }
    function test_unstake_tokens_still_locked() public { }
    function test_refreshDistributionFlow() public { }
    function test_extendLockingPeriod() public { }
    function test_extendLockingPeriod_not_staked_yet() public { }
    function test_extendLockingPeriod_lock_not_expired() public { }
    function test_extendLockingPeriod_invalid_locking_period() public { }
    function test_extendLockingPeriod_invalid_locking_period_too_short() public { }
    function test_extendLockingPeriod_invalid_locking_period_too_long() public { }

    function test_calculateMultiplier_characteristics(uint256 lockingPeriod) public view {
        lockingPeriod =
            bound(lockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        uint256 multiplier = _stakingPool.calculateMultiplier(lockingPeriod);

        assertEq(
            multiplier,
            _stakingPool.BASE_MULTIPLIER()
                + ((lockingPeriod - _stakingPool.MINIMUM_LOCKING_PERIOD()) * _stakingPool.MULTIPLIER_RANGE())
                    / _stakingPool.TIME_RANGE()
        );

        assertLe(multiplier, 360_000);
        assertGe(multiplier, 10_000);

        multiplier = _stakingPool.calculateMultiplier(_stakingPool.MINIMUM_LOCKING_PERIOD());
        assertEq(multiplier, _stakingPool.BASE_MULTIPLIER());

        multiplier = _stakingPool.calculateMultiplier(_stakingPool.MAXIMUM_LOCKING_PERIOD());
        assertEq(multiplier, _stakingPool.BASE_MULTIPLIER() + _stakingPool.MULTIPLIER_RANGE());
    }

    function _stake(address staker, uint256 amountToStake, uint256 lockingPeriod) internal {
        dealSuperToken(ADMIN, staker, _childToken, amountToStake);

        vm.startPrank(staker);
        _childToken.approve(address(_stakingPool), amountToStake);
        _stakingPool.stake(amountToStake, lockingPeriod);
        vm.stopPrank();

        assertEq(_stakingPool.getStakingInfo(staker).stakedAmount, amountToStake, "Staked amount mismatch");
        assertEq(
            _stakingPool.getStakingInfo(staker).multiplier,
            _stakingPool.calculateMultiplier(lockingPeriod),
            "Multiplier mismatch"
        );
        assertEq(
            _stakingPool.getStakingInfo(staker).lockedUntil, block.timestamp + lockingPeriod, "Locked until mismatch"
        );
    }

    function _stake_should_revert(address staker, uint256 amountToStake, uint256 lockingPeriod, bytes memory revertWith)
        internal
    {
        dealSuperToken(ADMIN, staker, _childToken, amountToStake);

        vm.startPrank(staker);
        _childToken.approve(address(_stakingPool), amountToStake);

        vm.expectRevert(revertWith);
        _stakingPool.stake(amountToStake, lockingPeriod);
        vm.stopPrank();
    }

}
