// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

/* Superfluid Imports */
import { IVestingSchedulerV3 } from
    "@superfluid-finance/automation-contracts/scheduler/contracts/interface/IVestingSchedulerV3.sol";
import { SuperTokenV1Library } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/* Local Imports */

import { ISpiritVesting } from "src/interfaces/vesting/ISpiritVesting.sol";
import { ISpiritVestingFactory } from "src/interfaces/vesting/ISpiritVestingFactory.sol";

using SuperTokenV1Library for ISuperToken;

/**
 * @title SPIRIT Token Vesting Contract
 * @notice Contract holding unvested SPIRIT tokens and acting as sender for the vesting scheduler
 */
contract SpiritVesting is ISpiritVesting {

    ISuperToken public immutable SPIRIT;
    address public immutable RECIPIENT;
    IVestingSchedulerV3 public immutable VESTING_SCHEDULER;
    ISpiritVestingFactory public immutable FACTORY;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice SpiritVesting contract constructor
     * @param vestingScheduler The Superfluid vesting scheduler contract
     * @param spirit The SPIRIT token contract
     * @param recipient The recipient of the vested tokens
     * @param cliffDate The timestamp when the cliff period ends and the flow can start
     * @param flowRate The rate at which tokens are streamed after the cliff period
     * @param cliffAmount The amount of tokens released at the cliff date
     * @param endDate The timestamp when the vesting schedule ends
     */
    constructor(
        IVestingSchedulerV3 vestingScheduler,
        ISuperToken spirit,
        address recipient,
        uint32 cliffDate,
        int96 flowRate,
        uint256 cliffAmount,
        uint32 endDate
    ) {
        // Grant flow and token allowances
        spirit.setMaxFlowPermissions(address(vestingScheduler));
        spirit.approve(address(vestingScheduler), type(uint256).max);

        // Create the vesting schedule for this recipient
        vestingScheduler.createVestingSchedule(
            spirit,
            recipient,
            uint32(block.timestamp),
            cliffDate,
            flowRate,
            cliffAmount,
            endDate,
            0 /* claimValidityDate */
        );

        SPIRIT = spirit;
        RECIPIENT = recipient;
        VESTING_SCHEDULER = vestingScheduler;
        FACTORY = ISpiritVestingFactory(msg.sender);
    }

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /// @inheritdoc ISpiritVesting
    function cancelVesting() external onlyAdmin {
        // Close the flow between this contract and the recipient
        SPIRIT.flow(RECIPIENT, 0);

        IVestingSchedulerV3.VestingSchedule memory vs =
            VESTING_SCHEDULER.getVestingSchedule(address(SPIRIT), address(this), RECIPIENT);
        if (vs.endDate != 0) {
            // Delete the vesting schedule if it is not already deleted
            VESTING_SCHEDULER.deleteVestingSchedule(SPIRIT, RECIPIENT);
        }
        // Fetch the remaining balance of the vesting contract
        uint256 remainingBalance = SPIRIT.balanceOf(address(this));

        // Transfer the remaining SUP tokens to the treasury
        SPIRIT.transfer(FACTORY.treasury(), remainingBalance);

        // Emit the `VestingDeleted` event
        emit VestingDeleted(remainingBalance);
    }

    //      __  ___          ___ _____
    //     /  |/  /___  ____/ (_) __(_)__  __________
    //    / /|_/ / __ \/ __  / / /_/ / _ \/ ___/ ___/
    //   / /  / / /_/ / /_/ / / __/ /  __/ /  (__  )
    //  /_/  /_/\____/\__,_/_/_/ /_/\___/_/  /____/

    /**
     * @notice Modifier to restrict access to admin only
     */
    modifier onlyAdmin() {
        if (msg.sender != FACTORY.treasury()) revert FORBIDDEN();
        _;
    }

}
