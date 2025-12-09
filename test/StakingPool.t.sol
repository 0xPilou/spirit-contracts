// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Math } from "@openzeppelin-v5/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin-v5/contracts/utils/math/SafeCast.sol";
import { SuperTokenV1Library } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";

import { IStakingPool } from "src/interfaces/core/IStakingPool.sol";
import { SpiritTestBase } from "test/base/SpiritTestBase.t.sol";

using SafeCast for int256;
using SuperTokenV1Library for ISuperToken;

contract StakingPoolTest is SpiritTestBase {

    // Contract under test
    IStakingPool internal _stakingPool;
    ISuperToken internal _childToken;

    uint256 internal constant _AVAILABLE_SUPPLY = 25_000_000 ether;
    uint256 internal constant _DOWNSCALER = 1e18;

    function setUp() public override {
        super.setUp();

        bytes32 salt = keccak256(abi.encode("SALT_FOR_NEW_CHILD_TOKEN"));

        // Deploy and initialize the StakingPool
        vm.prank(ADMIN);
        (_childToken, _stakingPool,,) = _spiritFactory.createChild(
            "Child Token", "CHILD", ARTIST, AGENT, _AVAILABLE_SUPPLY, bytes32(0), salt, DEFAULT_SQRT_PRICE_X96
        );
    }

    function test_initialize() public view {
        assertEq(address(_stakingPool.SPIRIT()), address(_spirit), "SPIRIT token mismatch");
        assertEq(address(_stakingPool.child()), address(_childToken), "Child token mismatch");
        assertNotEq(address(_stakingPool.distributionPool()), address(0), "Distribution pool not deployed");
        assertEq(_stakingPool.REWARD_CONTROLLER(), address(_rewardController), "Reward controller mismatch");
        assertEq(_stakingPool.distributionPool().getUnits(address(_stakingPool)), 1, "Pool units mismatch");
    }

    function test_stake(uint256 amountToStake, uint256 lockingPeriod) public {
        amountToStake = bound(amountToStake, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY);
        lockingPeriod =
            bound(lockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        _stake(ALICE, amountToStake, lockingPeriod);
    }

    function test_stake_already_staked(
        uint256 initialAmountToStake,
        uint256 additionalAmountToStake,
        uint256 lockingPeriod
    ) public {
        initialAmountToStake = bound(initialAmountToStake, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY / 2);
        additionalAmountToStake =
            bound(additionalAmountToStake, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY / 2);

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
        amountToStake = bound(amountToStake, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY);
        invalidLockingPeriod = bound(invalidLockingPeriod, 0, _stakingPool.MINIMUM_LOCKING_PERIOD() - 1);

        _stake_should_revert(
            ALICE,
            amountToStake,
            invalidLockingPeriod,
            abi.encodeWithSelector(IStakingPool.INVALID_LOCKING_PERIOD.selector)
        );
    }

    function test_stake_invalid_locking_period_too_long(uint256 amountToStake, uint256 invalidLockingPeriod) public {
        amountToStake = bound(amountToStake, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY);

        invalidLockingPeriod =
            bound(invalidLockingPeriod, _stakingPool.MAXIMUM_LOCKING_PERIOD() + 1, uint256(type(uint256).max));

        _stake_should_revert(
            ALICE,
            amountToStake,
            invalidLockingPeriod,
            abi.encodeWithSelector(IStakingPool.INVALID_LOCKING_PERIOD.selector)
        );
    }

    function test_increaseStake(
        uint256 initialStakedAmount,
        uint256 initialLockingPeriod,
        uint256 amountToStake,
        uint256 increaseStakeTimestamp
    ) public {
        initialStakedAmount = bound(initialStakedAmount, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY / 2);
        amountToStake = bound(amountToStake, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY / 2);
        initialLockingPeriod =
            bound(initialLockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());
        increaseStakeTimestamp = bound(increaseStakeTimestamp, 0, _stakingPool.MAXIMUM_LOCKING_PERIOD() * 10);

        _stake(ALICE, initialStakedAmount, initialLockingPeriod);

        vm.warp(block.timestamp + increaseStakeTimestamp);

        bool withBonus =
            !(block.timestamp + _stakingPool.MINIMUM_LOCKING_PERIOD() > _stakingPool.getStakingInfo(ALICE).lockedUntil);
        _increaseStake(ALICE, amountToStake, withBonus);
    }

    function test_increaseStake_not_staked_yet(uint256 amountToStake) public {
        amountToStake = bound(amountToStake, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY / 2);
        _increaseStake_should_revert(ALICE, amountToStake, abi.encodeWithSelector(IStakingPool.NOT_STAKED_YET.selector));
    }

    function test_increaseStake_invalid_stake_amount(
        uint256 initialStakedAmount,
        uint256 initialLockingPeriod,
        uint256 amountToStake,
        uint256 increaseStakeTimestamp
    ) public {
        initialStakedAmount = bound(initialStakedAmount, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY / 2);
        amountToStake = bound(amountToStake, 0, _stakingPool.MINIMUM_STAKE_AMOUNT() - 1);
        initialLockingPeriod =
            bound(initialLockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());
        increaseStakeTimestamp = bound(increaseStakeTimestamp, 0, _stakingPool.MAXIMUM_LOCKING_PERIOD() * 10);

        _stake(ALICE, initialStakedAmount, initialLockingPeriod);

        vm.warp(block.timestamp + increaseStakeTimestamp);

        _increaseStake_should_revert(
            ALICE, amountToStake, abi.encodeWithSelector(IStakingPool.INVALID_STAKE_AMOUNT.selector)
        );
    }

    function test_extendLockingPeriod(
        uint256 initialStakedAmount,
        uint256 initialLockingPeriod,
        uint256 newLockingPeriod,
        uint256 extendLockingPeriodTimestamp
    ) public {
        initialStakedAmount = bound(initialStakedAmount, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY);
        initialLockingPeriod =
            bound(initialLockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        newLockingPeriod =
            bound(newLockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        extendLockingPeriodTimestamp = bound(
            extendLockingPeriodTimestamp,
            initialLockingPeriod + block.timestamp,
            initialLockingPeriod + _stakingPool.MAXIMUM_LOCKING_PERIOD() * 10
        );

        _stake(ALICE, initialStakedAmount, initialLockingPeriod);

        vm.warp(extendLockingPeriodTimestamp);

        _extendLockingPeriod(ALICE, newLockingPeriod);
    }

    function test_extendLockingPeriod_not_staked_yet(uint256 newLockingPeriod) public {
        newLockingPeriod =
            bound(newLockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        _extendLockingPeriod_should_revert(
            ALICE, newLockingPeriod, abi.encodeWithSelector(IStakingPool.NOT_STAKED_YET.selector)
        );
    }

    function test_extendLockingPeriod_lock_not_expired(
        uint256 initialStakedAmount,
        uint256 initialLockingPeriod,
        uint256 newLockingPeriod,
        uint256 invalidExtendLockingPeriodTimestamp
    ) public {
        initialStakedAmount = bound(initialStakedAmount, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY);
        initialLockingPeriod =
            bound(initialLockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        newLockingPeriod =
            bound(newLockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        invalidExtendLockingPeriodTimestamp =
            bound(invalidExtendLockingPeriodTimestamp, 0, initialLockingPeriod + block.timestamp - 1);

        _stake(ALICE, initialStakedAmount, initialLockingPeriod);

        vm.warp(invalidExtendLockingPeriodTimestamp);

        _extendLockingPeriod_should_revert(
            ALICE, newLockingPeriod, abi.encodeWithSelector(IStakingPool.LOCK_NOT_EXPIRED.selector)
        );
    }

    function test_extendLockingPeriod_invalid_locking_period_too_short(
        uint256 initialStakedAmount,
        uint256 initialLockingPeriod,
        uint256 newLockingPeriodTooShort,
        uint256 extendLockingPeriodTimestamp
    ) public {
        initialStakedAmount = bound(initialStakedAmount, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY);
        initialLockingPeriod =
            bound(initialLockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        newLockingPeriodTooShort = bound(newLockingPeriodTooShort, 0, _stakingPool.MINIMUM_LOCKING_PERIOD() - 1);

        extendLockingPeriodTimestamp = bound(
            extendLockingPeriodTimestamp,
            initialLockingPeriod + block.timestamp,
            initialLockingPeriod + _stakingPool.MAXIMUM_LOCKING_PERIOD() * 10
        );

        _stake(ALICE, initialStakedAmount, initialLockingPeriod);

        vm.warp(extendLockingPeriodTimestamp);

        _extendLockingPeriod_should_revert(
            ALICE, newLockingPeriodTooShort, abi.encodeWithSelector(IStakingPool.INVALID_LOCKING_PERIOD.selector)
        );
    }

    function test_extendLockingPeriod_invalid_locking_period_too_long(
        uint256 initialStakedAmount,
        uint256 initialLockingPeriod,
        uint256 newLockingPeriodTooLong,
        uint256 extendLockingPeriodTimestamp
    ) public {
        initialStakedAmount = bound(initialStakedAmount, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY);
        initialLockingPeriod =
            bound(initialLockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        newLockingPeriodTooLong = bound(
            newLockingPeriodTooLong,
            _stakingPool.MAXIMUM_LOCKING_PERIOD() + 1,
            _stakingPool.MAXIMUM_LOCKING_PERIOD() * 10
        );

        extendLockingPeriodTimestamp = bound(
            extendLockingPeriodTimestamp,
            initialLockingPeriod + block.timestamp,
            initialLockingPeriod + _stakingPool.MAXIMUM_LOCKING_PERIOD() * 10
        );

        _stake(ALICE, initialStakedAmount, initialLockingPeriod);

        vm.warp(extendLockingPeriodTimestamp);

        _extendLockingPeriod_should_revert(
            ALICE, newLockingPeriodTooLong, abi.encodeWithSelector(IStakingPool.INVALID_LOCKING_PERIOD.selector)
        );
    }

    function test_unstake(uint256 initialStakedAmount, uint256 lockingPeriod, uint256 invalidAmountToUnstake) public {
        initialStakedAmount = bound(initialStakedAmount, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY);
        invalidAmountToUnstake = bound(invalidAmountToUnstake, _stakingPool.MINIMUM_STAKE_AMOUNT(), initialStakedAmount);

        lockingPeriod =
            bound(lockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        _stake(ALICE, initialStakedAmount, lockingPeriod);

        vm.warp(lockingPeriod + block.timestamp);
        _unstake(ALICE, invalidAmountToUnstake);
    }

    function test_unstake_invalid_stake_amount(
        uint256 initialStakedAmount,
        uint256 lockingPeriod,
        uint256 invalidAmountToUnstake
    ) public {
        initialStakedAmount = bound(initialStakedAmount, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY);
        invalidAmountToUnstake = bound(invalidAmountToUnstake, 0, _stakingPool.MINIMUM_STAKE_AMOUNT() - 1);

        lockingPeriod =
            bound(lockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        _stake(ALICE, initialStakedAmount, lockingPeriod);

        vm.warp(lockingPeriod + block.timestamp);
        _unstake_should_revert(
            ALICE, invalidAmountToUnstake, abi.encodeWithSelector(IStakingPool.INVALID_STAKE_AMOUNT.selector)
        );
    }

    function test_unstake_insufficient_staked_amount(
        uint256 initialStakedAmount,
        uint256 lockingPeriod,
        uint256 amountToUnstake
    ) public {
        initialStakedAmount = bound(initialStakedAmount, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY / 2);
        amountToUnstake = bound(amountToUnstake, initialStakedAmount + 1, _AVAILABLE_SUPPLY);

        lockingPeriod =
            bound(lockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        _stake(ALICE, initialStakedAmount, lockingPeriod);

        vm.warp(lockingPeriod + block.timestamp);
        _unstake_should_revert(
            ALICE, amountToUnstake, abi.encodeWithSelector(IStakingPool.INSUFFICIENT_STAKED_AMOUNT.selector)
        );
    }

    function test_unstake_tokens_still_locked(
        uint256 initialStakedAmount,
        uint256 lockingPeriod,
        uint256 invalidAmountToUnstake,
        uint256 invalidUnstakeTimestamp
    ) public {
        initialStakedAmount = bound(initialStakedAmount, _stakingPool.MINIMUM_STAKE_AMOUNT(), _AVAILABLE_SUPPLY);
        invalidAmountToUnstake = bound(invalidAmountToUnstake, _stakingPool.MINIMUM_STAKE_AMOUNT(), initialStakedAmount);
        lockingPeriod =
            bound(lockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());
        invalidUnstakeTimestamp = bound(invalidUnstakeTimestamp, 0, lockingPeriod + block.timestamp - 1);

        _stake(ALICE, initialStakedAmount, lockingPeriod);

        vm.warp(invalidUnstakeTimestamp);
        _unstake_should_revert(
            ALICE, invalidAmountToUnstake, abi.encodeWithSelector(IStakingPool.TOKENS_STILL_LOCKED.selector)
        );
    }

    function test_refreshDistributionFlow(uint256 amountToDistribute) public {
        amountToDistribute = bound(amountToDistribute, 1e18, _AVAILABLE_SUPPLY);

        dealSuperToken(TREASURY, address(_rewardController), _spirit, amountToDistribute);

        vm.startPrank(address(_rewardController));
        _spirit.transfer(address(_stakingPool), amountToDistribute);
        _stakingPool.refreshDistributionFlow();
        vm.stopPrank();

        int96 expectedFlowRate = int256(amountToDistribute / _stakingPool.STREAM_OUT_DURATION()).toInt96();
        assertApproxEqAbs(
            int256(_spirit.getFlowRate(address(_stakingPool), address(_stakingPool.distributionPool()))),
            int256(expectedFlowRate),
            uint256(int256(expectedFlowRate * 100 / 10_000)), // allow 1% error tolerance
            "Flow rate mismatch"
        );
    }

    function test_refreshDistributionFlow_not_reward_controller(address notRewardController, uint256 amountToDistribute)
        public
    {
        vm.assume(notRewardController != address(_rewardController));
        vm.assume(notRewardController != address(_stakingPool));
        vm.assume(notRewardController != address(_stakingPool.distributionPool()));
        vm.assume(notRewardController != address(0));

        amountToDistribute = bound(amountToDistribute, 1e18, _AVAILABLE_SUPPLY);

        dealSuperToken(TREASURY, notRewardController, _spirit, amountToDistribute);

        vm.startPrank(notRewardController);
        _spirit.transfer(address(_stakingPool), amountToDistribute);

        vm.expectRevert(abi.encodeWithSelector(IStakingPool.NOT_REWARD_CONTROLLER.selector));
        _stakingPool.refreshDistributionFlow();
        vm.stopPrank();
    }

    function test_terminateDistributionFlow(address nonRewardController, uint256 amountToDistribute, uint256 deltaTime)
        public
    {
        amountToDistribute = bound(amountToDistribute, 1e18, _AVAILABLE_SUPPLY);
        deltaTime = bound(deltaTime, 1, _stakingPool.STREAM_OUT_DURATION() - 1 minutes);

        vm.assume(nonRewardController != address(_rewardController));

        dealSuperToken(TREASURY, address(_rewardController), _spirit, amountToDistribute);

        vm.startPrank(address(_rewardController));
        _spirit.transfer(address(_stakingPool), amountToDistribute);
        _stakingPool.refreshDistributionFlow();
        vm.stopPrank();

        int96 expectedFlowRate = int256(amountToDistribute / _stakingPool.STREAM_OUT_DURATION()).toInt96();
        assertApproxEqAbs(
            int256(_spirit.getFlowRate(address(_stakingPool), address(_stakingPool.distributionPool()))),
            int256(expectedFlowRate),
            uint256(int256(expectedFlowRate * 100 / 10_000)), // allow 1% error tolerance
            "Flow rate mismatch"
        );

        vm.startPrank(ARTIST);
        _spirit.connectPool(_stakingPool.distributionPool());
        vm.stopPrank();

        vm.startPrank(AGENT);
        _spirit.connectPool(_stakingPool.distributionPool());
        vm.stopPrank();

        address remainderRecipient = makeAddr("remainderRecipient");

        assertGt(_spirit.balanceOf(address(_stakingPool)), 0, "Staking pool balance should be greater than 0");

        vm.warp(block.timestamp + deltaTime);

        vm.prank(nonRewardController);
        vm.expectRevert(abi.encodeWithSelector(IStakingPool.NOT_REWARD_CONTROLLER.selector));
        _stakingPool.terminateDistributionFlow(remainderRecipient);

        vm.prank(address(_rewardController));
        _stakingPool.terminateDistributionFlow(remainderRecipient);

        assertEq(_spirit.balanceOf(address(_stakingPool)), 0, "Staking pool balance should be 0");

        uint256 artistBalance = _spirit.balanceOf(ARTIST);
        uint256 agentBalance = _spirit.balanceOf(AGENT);
        uint256 remainderRecipientBalance = _spirit.balanceOf(remainderRecipient);

        assertApproxEqAbs(
            artistBalance + agentBalance + remainderRecipientBalance,
            amountToDistribute,
            uint256(int256(amountToDistribute / 10_000)), // allow 0.01% error tolerance
            "Total balance should be equal to the distributed amount"
        );
    }

    function test_terminateDistributionFlow_noStakers(uint256 amountToDistribute, uint256 deltaTime) public {
        vm.warp(block.timestamp + 53 weeks);

        uint256 agentStakedAmount = _stakingPool.getStakingInfo(AGENT).stakedAmount;
        uint256 artistStakedAmount = _stakingPool.getStakingInfo(ARTIST).stakedAmount;

        vm.prank(AGENT);
        _stakingPool.unstake(agentStakedAmount);

        vm.prank(ARTIST);
        _stakingPool.unstake(artistStakedAmount);

        amountToDistribute = bound(amountToDistribute, 1e18, _AVAILABLE_SUPPLY);
        deltaTime = bound(deltaTime, 1, _stakingPool.STREAM_OUT_DURATION() - 5 hours);

        dealSuperToken(TREASURY, address(_rewardController), _spirit, amountToDistribute);

        vm.startPrank(address(_rewardController));
        _spirit.transfer(address(_stakingPool), amountToDistribute);
        _stakingPool.refreshDistributionFlow();
        vm.stopPrank();

        int96 expectedFlowRate = int256(amountToDistribute / _stakingPool.STREAM_OUT_DURATION()).toInt96();
        assertApproxEqAbs(
            int256(_spirit.getFlowRate(address(_stakingPool), address(_stakingPool.distributionPool()))),
            int256(expectedFlowRate),
            uint256(int256(expectedFlowRate * 100 / 10_000)), // allow 1% error tolerance
            "Flow rate mismatch"
        );

        vm.warp(block.timestamp + deltaTime);

        address remainderRecipient = makeAddr("remainderRecipient");

        vm.prank(address(_rewardController));
        vm.expectRevert(abi.encodeWithSelector(IStakingPool.NO_MEMBERS_IN_POOL.selector));
        _stakingPool.terminateDistributionFlow(remainderRecipient);
    }

    function test_calculateMultiplier_characteristics(uint256 lockingPeriod) public view {
        lockingPeriod =
            bound(lockingPeriod, _stakingPool.MINIMUM_LOCKING_PERIOD(), _stakingPool.MAXIMUM_LOCKING_PERIOD());

        uint256 multiplier = _stakingPool.calculateMultiplier(lockingPeriod);

        assertEq(
            multiplier,
            _stakingPool.MIN_MULTIPLIER()
                + ((lockingPeriod - _stakingPool.MINIMUM_LOCKING_PERIOD()) * _stakingPool.MULTIPLIER_RANGE())
                    / _stakingPool.TIME_RANGE()
        );

        assertGe(multiplier, _stakingPool.MIN_MULTIPLIER());
        assertLe(multiplier, _stakingPool.MAX_MULTIPLIER());

        assertEq(_stakingPool.calculateMultiplier(_stakingPool.MINIMUM_LOCKING_PERIOD()), _stakingPool.MIN_MULTIPLIER());
        assertEq(_stakingPool.calculateMultiplier(_stakingPool.MAXIMUM_LOCKING_PERIOD()), _stakingPool.MAX_MULTIPLIER());
    }

    // Helper functions
    function _stake(address staker, uint256 amountToStake, uint256 lockingPeriod) internal {
        dealSuperToken(ADMIN, staker, _childToken, amountToStake);

        vm.startPrank(staker);
        _childToken.approve(address(_stakingPool), amountToStake);
        _stakingPool.stake(amountToStake, lockingPeriod);
        vm.stopPrank();

        assertEq(_stakingPool.getStakingInfo(staker).stakedAmount, amountToStake, "Staked amount mismatch");

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

    function _increaseStake(address staker, uint256 amountToStake, bool withBonus) internal {
        dealSuperToken(ADMIN, staker, _childToken, amountToStake);

        uint256 initialStakedAmount = _stakingPool.getStakingInfo(staker).stakedAmount;
        uint256 initialLockedUntil = _stakingPool.getStakingInfo(staker).lockedUntil;
        uint128 initialUnits = _stakingPool.distributionPool().getUnits(staker);

        assertGt(initialStakedAmount, 0, "Initial staked amount should be greater than 0");
        assertGt(initialLockedUntil, 0, "Unlocking Date should be greater than 0");
        assertGt(initialUnits, 0, "Initial units should be greater than 0");

        vm.startPrank(staker);
        _childToken.approve(address(_stakingPool), amountToStake);
        _stakingPool.increaseStake(amountToStake);
        vm.stopPrank();

        uint256 expectedMultiplier = withBonus
            ? _stakingPool.calculateMultiplier(_stakingPool.getStakingInfo(staker).lockedUntil - block.timestamp)
            : _stakingPool.MIN_MULTIPLIER();

        uint128 expectedNewUnits =
            uint128((amountToStake * expectedMultiplier) / (_stakingPool.MIN_MULTIPLIER() * _DOWNSCALER));

        assertEq(_stakingPool.distributionPool().getUnits(staker), initialUnits + expectedNewUnits, "Units mismatch");

        assertEq(
            _stakingPool.getStakingInfo(staker).stakedAmount,
            initialStakedAmount + amountToStake,
            "Staked amount mismatch"
        );

        assertEq(
            _stakingPool.getStakingInfo(staker).lockedUntil, initialLockedUntil, "Unlocking Date should not change"
        );
    }

    function _increaseStake_should_revert(address staker, uint256 amountToStake, bytes memory revertWith) internal {
        dealSuperToken(ADMIN, staker, _childToken, amountToStake);

        vm.startPrank(staker);
        _childToken.approve(address(_stakingPool), amountToStake);

        vm.expectRevert(revertWith);
        _stakingPool.increaseStake(amountToStake);
        vm.stopPrank();
    }

    function _extendLockingPeriod(address staker, uint256 newLockingPeriod) internal {
        assertGe(
            block.timestamp,
            _stakingPool.getStakingInfo(staker).lockedUntil,
            "Cannot extend before locking period expires"
        );

        uint256 initialUnits = _stakingPool.distributionPool().getUnits(staker);

        vm.startPrank(staker);
        _stakingPool.extendLockingPeriod(newLockingPeriod);
        vm.stopPrank();

        uint256 expectedMultiplier =
            _stakingPool.calculateMultiplier(_stakingPool.getStakingInfo(staker).lockedUntil - block.timestamp);

        uint128 expectedAddedUnits = uint128(
            (_stakingPool.getStakingInfo(staker).stakedAmount * expectedMultiplier)
                / (_stakingPool.MIN_MULTIPLIER() * _DOWNSCALER)
        );

        assertEq(_stakingPool.distributionPool().getUnits(staker), initialUnits + expectedAddedUnits, "Units mismatch");
        assertEq(
            _stakingPool.getStakingInfo(staker).lockedUntil,
            block.timestamp + newLockingPeriod,
            "Unlocking Date mismatch"
        );
    }

    function _extendLockingPeriod_should_revert(address staker, uint256 newLockingPeriod, bytes memory revertWith)
        internal
    {
        vm.startPrank(staker);
        vm.expectRevert(revertWith);
        _stakingPool.extendLockingPeriod(newLockingPeriod);
        vm.stopPrank();
    }

    function _unstake(address staker, uint256 amountToUnstake) internal {
        uint256 initialStakedAmount = _stakingPool.getStakingInfo(staker).stakedAmount;
        uint256 initialLockedUntil = _stakingPool.getStakingInfo(staker).lockedUntil;
        uint128 initialUnits = _stakingPool.distributionPool().getUnits(staker);
        uint256 initialStakerBalance = _childToken.balanceOf(staker);
        uint256 initialStakingPoolBalance = _childToken.balanceOf(address(_stakingPool));

        assertGt(initialStakedAmount, 0, "Initial staked amount should be greater than 0");
        assertLe(initialLockedUntil, block.timestamp, "Unlocking Date should be expired");
        assertGt(initialUnits, 0, "Initial units should be greater than 0");
        assertGt(initialStakingPoolBalance, 0, "Initial staking pool balance should be greater than 0");

        // Use proportional calculation to match the implementation
        uint128 expectedCalculatedRemovedUnits =
            uint128(Math.ceilDiv(amountToUnstake * initialUnits, initialStakedAmount));
        uint128 expectedRemovedUnits = uint128(Math.min(expectedCalculatedRemovedUnits, initialUnits));

        vm.startPrank(staker);
        _stakingPool.unstake(amountToUnstake);
        vm.stopPrank();

        assertEq(
            _stakingPool.getStakingInfo(staker).stakedAmount,
            initialStakedAmount - amountToUnstake,
            "Staked amount mismatch after unstake"
        );

        if (initialStakedAmount - amountToUnstake == 0) {
            assertEq(
                _stakingPool.getStakingInfo(staker).lockedUntil, 0, "Unlocking Date should be 0 after total unstake"
            );
            assertEq(_stakingPool.distributionPool().getUnits(staker), 0, "Units should be 0 after total unstake");
        } else {
            assertEq(
                _stakingPool.getStakingInfo(staker).lockedUntil,
                initialLockedUntil,
                "Unlocking Date should not change after partial unstake"
            );
            assertEq(
                _stakingPool.distributionPool().getUnits(staker),
                initialUnits - expectedRemovedUnits,
                "Units mismatch after partial unstake"
            );
        }

        assertEq(
            _childToken.balanceOf(staker),
            initialStakerBalance + amountToUnstake,
            "Staker balance mismatch after unstake"
        );
        assertEq(
            _childToken.balanceOf(address(_stakingPool)),
            initialStakingPoolBalance - amountToUnstake,
            "Staking pool balance mismatch after unstake"
        );
    }

    function _unstake_should_revert(address staker, uint256 amountToUnstake, bytes memory revertWith) internal {
        vm.startPrank(staker);
        vm.expectRevert(revertWith);
        _stakingPool.unstake(amountToUnstake);
        vm.stopPrank();
    }

}
