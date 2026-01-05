// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { SafeCast } from "@openzeppelin-v5/contracts/utils/math/SafeCast.sol";

import { SuperTokenV1Library } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IRewardController } from "src/interfaces/core/IRewardController.sol";
import { IStakingPool } from "src/interfaces/core/IStakingPool.sol";
import { SpiritTestBase } from "test/base/SpiritTestBase.t.sol";

using SafeCast for int256;
using SuperTokenV1Library for ISuperToken;

contract RewardControllerTest is SpiritTestBase {

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

    function test_setStakingPool(address child, address stakingPool) public {
        vm.assume(child != address(0));
        vm.assume(stakingPool != address(0));

        vm.prank(address(_spiritFactory));
        _rewardController.setStakingPool(child, IStakingPool(stakingPool));

        assertEq(address(_rewardController.stakingPools(child)), stakingPool);
    }

    function test_setStakingPool_invalid_caller(address invalidCaller, address child, address stakingPool) public {
        vm.assume(child != address(0));
        vm.assume(stakingPool != address(0));
        vm.assume(invalidCaller != address(_spiritFactory));

        vm.prank(invalidCaller);
        vm.expectRevert();
        _rewardController.setStakingPool(child, IStakingPool(stakingPool));
    }

    function test_setStakingPool_invalid_child(address stakingPool) public {
        vm.assume(stakingPool != address(0));

        vm.prank(address(_spiritFactory));
        vm.expectRevert(IRewardController.INVALID_CHILD.selector);
        _rewardController.setStakingPool(address(0), IStakingPool(stakingPool));
    }

    function test_setStakingPool_staking_pool_already_set(address child, address stakingPool1, address stakingPool2)
        public
    {
        vm.assume(child != address(0));
        vm.assume(stakingPool1 != address(0));
        vm.assume(stakingPool2 != address(0));
        vm.assume(stakingPool1 != stakingPool2);

        vm.prank(address(_spiritFactory));
        _rewardController.setStakingPool(child, IStakingPool(stakingPool1));

        assertEq(address(_rewardController.stakingPools(child)), stakingPool1);

        vm.prank(address(_spiritFactory));
        vm.expectRevert(IRewardController.STAKING_POOL_ALREADY_SET.selector);
        _rewardController.setStakingPool(child, IStakingPool(stakingPool2));
    }

    function test_distributeRewards(uint256 amount) public {
        amount = bound(amount, 1 ether, _spirit.balanceOf(TREASURY));
        dealSuperToken(TREASURY, ADMIN, _spirit, amount);

        (ISuperToken childToken, IStakingPool stakingPool) = _setupChild();

        vm.startPrank(ADMIN);
        _spirit.approve(address(_rewardController), amount);
        _rewardController.distributeRewards(address(childToken), amount);
        vm.stopPrank();

        int96 expectedFlowRate = int256(amount / stakingPool.STREAM_OUT_DURATION()).toInt96();
        assertApproxEqAbs(
            int256(_spirit.getFlowRate(address(stakingPool), address(stakingPool.distributionPool()))),
            int256(expectedFlowRate),
            uint256(int256(expectedFlowRate * 100 / 10_000)), // allow 1% error tolerance
            "Flow rate mismatch"
        );
    }

    function test_distributeRewards_invalid_caller(address invalidCaller, uint256 amount) public {
        vm.assume(_rewardController.hasRole(_rewardController.DISTRIBUTOR_ROLE(), invalidCaller) != true);
        vm.assume(invalidCaller != address(0));

        amount = bound(amount, 1 ether, _spirit.balanceOf(TREASURY));
        dealSuperToken(TREASURY, ADMIN, _spirit, amount);

        (ISuperToken childToken,) = _setupChild();

        vm.startPrank(invalidCaller);
        _spirit.approve(address(_rewardController), amount);

        vm.expectRevert();
        _rewardController.distributeRewards(address(childToken), amount);
        vm.stopPrank();
    }

    function test_distributeRewards_staking_pool_not_found(address nonLinkedChild, uint256 amount) public {
        amount = bound(amount, 1 ether, _spirit.balanceOf(TREASURY));
        dealSuperToken(TREASURY, ADMIN, _spirit, amount);

        vm.startPrank(ADMIN);
        _spirit.approve(address(_rewardController), amount);

        vm.expectRevert(IRewardController.STAKING_POOL_NOT_FOUND.selector);
        _rewardController.distributeRewards(nonLinkedChild, amount);
        vm.stopPrank();
    }

    function test_distributeRewards_invalid_amount() public {
        uint256 amount = 0;
        dealSuperToken(TREASURY, ADMIN, _spirit, amount);

        (ISuperToken childToken,) = _setupChild();

        vm.startPrank(ADMIN);
        _spirit.approve(address(_rewardController), amount);

        vm.expectRevert(IRewardController.INVALID_AMOUNT.selector);
        _rewardController.distributeRewards(address(childToken), amount);
        vm.stopPrank();
    }

    function test_terminateDistribution(address nonDistributor, uint256 amount) public {
        vm.assume(nonDistributor != ADMIN);
        amount = bound(amount, 1 ether, _spirit.balanceOf(TREASURY));
        dealSuperToken(TREASURY, ADMIN, _spirit, amount);

        (ISuperToken childToken, IStakingPool stakingPool) = _setupChild();

        vm.startPrank(ADMIN);
        _spirit.approve(address(_rewardController), amount);
        _rewardController.distributeRewards(address(childToken), amount);
        vm.stopPrank();

        int96 expectedFlowRate = int256(amount / stakingPool.STREAM_OUT_DURATION()).toInt96();
        assertApproxEqAbs(
            int256(_spirit.getFlowRate(address(stakingPool), address(stakingPool.distributionPool()))),
            int256(expectedFlowRate),
            uint256(int256(expectedFlowRate * 100 / 10_000)), // allow 1% error tolerance
            "Flow rate mismatch"
        );

        vm.prank(nonDistributor);
        vm.expectRevert();
        _rewardController.terminateDistribution(address(childToken));

        vm.prank(ADMIN);
        _rewardController.terminateDistribution(address(childToken));

        assertEq(
            _spirit.getFlowRate(address(stakingPool), address(stakingPool.distributionPool())),
            0,
            "Flow distribution should be terminated"
        );
    }

    function test_terminateDistribution_staking_pool_not_found(
        address nonLinkedChild,
        address nonDistributor,
        uint256 amount
    ) public {
        vm.assume(nonLinkedChild != address(0));
        vm.assume(nonDistributor != ADMIN);

        amount = bound(amount, 1 ether, _spirit.balanceOf(TREASURY));
        dealSuperToken(TREASURY, ADMIN, _spirit, amount);

        (ISuperToken childToken, IStakingPool stakingPool) = _setupChild();

        vm.assume(nonLinkedChild != address(childToken));

        vm.startPrank(ADMIN);
        _spirit.approve(address(_rewardController), amount);
        _rewardController.distributeRewards(address(childToken), amount);
        vm.stopPrank();

        int96 expectedFlowRate = int256(amount / stakingPool.STREAM_OUT_DURATION()).toInt96();
        assertApproxEqAbs(
            int256(_spirit.getFlowRate(address(stakingPool), address(stakingPool.distributionPool()))),
            int256(expectedFlowRate),
            uint256(int256(expectedFlowRate * 100 / 10_000)), // allow 1% error tolerance
            "Flow rate mismatch"
        );

        vm.prank(ADMIN);
        vm.expectRevert(IRewardController.STAKING_POOL_NOT_FOUND.selector);
        _rewardController.terminateDistribution(nonLinkedChild);
    }

    function _setupChild() internal returns (ISuperToken childToken, IStakingPool stakingPool) {
        bytes32 salt = keccak256(abi.encode("SALT_FOR_NEW_CHILD_TOKEN"));

        vm.prank(ADMIN);
        (childToken, stakingPool,,) = _spiritFactory.createChild(
            "New Child Token", "NEWCHILD", ARTIST, AGENT, TREASURY, bytes32(0), salt, DEFAULT_SQRT_PRICE_X96
        );

        assertEq(address(_rewardController.stakingPools(address(childToken))), address(stakingPool));
    }

}
