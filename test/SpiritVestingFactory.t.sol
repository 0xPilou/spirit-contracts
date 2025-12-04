// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { SafeCast } from "@openzeppelin-v5/contracts/utils/math/SafeCast.sol";
import { VestingSchedulerV2 } from "@superfluid-finance/automation-contracts/scheduler/contracts/VestingSchedulerV2.sol";
import { IVestingSchedulerV2 } from
    "@superfluid-finance/automation-contracts/scheduler/contracts/interface/IVestingSchedulerV2.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/superfluid/SuperToken.sol";
import { ISpiritVestingFactory, SpiritVestingFactory } from "src/vesting/SpiritVestingFactory.sol";

import { SpiritTestBase } from "test/base/SpiritTestBase.t.sol";

using SafeCast for int256;

contract SpiritVestingFactoryTest is SpiritTestBase {

    // 2 years vesting
    uint32 public constant VESTING_DURATION = 730 days;

    // 1 year cliff
    uint32 public constant CLIFF_PERIOD = 365 days;

    function setUp() public virtual override {
        super.setUp();

        // Move time forward to avoid vesting scheduler errors (time based input validation constraints)
        vm.warp(block.timestamp + 420 days);
    }

    function testCreateSpiritVestingContract(address nonAdmin, address recipient, uint256 amount, uint256 cliffAmount)
        public
    {
        vm.assume(nonAdmin != address(TREASURY));
        vm.assume(recipient != address(0));
        amount = bound(amount, 1 ether, 1_000_000 ether);
        cliffAmount = bound(cliffAmount, 1, amount - 0.1 ether);

        uint32 cliffDate = uint32(block.timestamp + CLIFF_PERIOD);

        vm.prank(TREASURY);
        _spirit.approve(address(_spiritVestingFactory), amount);

        vm.prank(nonAdmin);
        vm.expectRevert(ISpiritVestingFactory.FORBIDDEN.selector);
        _spiritVestingFactory.createSpiritVestingContract(
            recipient, amount, cliffAmount, cliffDate, uint32(block.timestamp + CLIFF_PERIOD + VESTING_DURATION)
        );

        vm.prank(TREASURY);
        _spiritVestingFactory.createSpiritVestingContract(
            recipient, amount, cliffAmount, cliffDate, uint32(block.timestamp + CLIFF_PERIOD + VESTING_DURATION)
        );

        address newSpiritVestingContract = _spiritVestingFactory.spiritVestings(recipient);

        assertNotEq(newSpiritVestingContract, address(0), "New spirit vesting contract should be created");
        assertEq(_spiritVestingFactory.balanceOf(recipient), amount, "Balance should be updated");

        vm.prank(TREASURY);
        vm.expectRevert(ISpiritVestingFactory.RECIPIENT_ALREADY_HAS_VESTING_CONTRACT.selector);
        _spiritVestingFactory.createSpiritVestingContract(
            recipient, amount, cliffAmount, cliffDate, uint32(block.timestamp + CLIFF_PERIOD + VESTING_DURATION)
        );
    }

    function testSetTreasury(address newTreasury, address nonTreasury) public {
        vm.assume(nonTreasury != address(TREASURY));
        vm.assume(newTreasury != address(TREASURY));
        vm.assume(newTreasury != address(0));

        vm.prank(nonTreasury);
        vm.expectRevert(ISpiritVestingFactory.FORBIDDEN.selector);
        _spiritVestingFactory.setTreasury(newTreasury);

        vm.startPrank(TREASURY);
        vm.expectRevert(ISpiritVestingFactory.FORBIDDEN.selector);
        _spiritVestingFactory.setTreasury(address(0));

        _spiritVestingFactory.setTreasury(newTreasury);
        vm.stopPrank();

        assertEq(_spiritVestingFactory.treasury(), newTreasury, "Treasury should be updated to the new treasury");
    }

}
