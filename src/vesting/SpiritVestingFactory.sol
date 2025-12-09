// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/* Superfluid Imports */
import { IVestingSchedulerV3 } from
    "@superfluid-finance/automation-contracts/scheduler/contracts/interface/IVestingSchedulerV3.sol";
import { SuperTokenV1Library } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/* Local Imports */
import { ISpiritVestingFactory } from "src/interfaces/vesting/ISpiritVestingFactory.sol";
import { SpiritVesting } from "src/vesting/SpiritVesting.sol";

using SuperTokenV1Library for ISuperToken;
using SafeCast for int256;

/**
 * @title SPIRIT Token Vesting Factory Contract
 * @notice Contract deploying new SPIRIT Token Vesting contracts
 */
contract SpiritVestingFactory is ISpiritVestingFactory {

    //      ____                          __        __    __        _____ __        __
    //     /  _/___ ___  ____ ___  __  __/ /_____ _/ /_  / /__     / ___// /_____ _/ /____  _____
    //     / // __ `__ \/ __ `__ \/ / / / __/ __ `/ __ \/ / _ \    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   _/ // / / / / / / / / / / /_/ / /_/ /_/ / /_/ / /  __/   ___/ / /_/ /_/ / /_/  __(__  )
    //  /___/_/ /_/ /_/_/ /_/ /_/\__,_/\__/\__,_/_.___/_/\___/   /____/\__/\__,_/\__/\___/____/

    /// @notice Superfluid Vesting Scheduler contract address
    IVestingSchedulerV3 public immutable VESTING_SCHEDULER;

    /// @notice SPIRIT Token contract address
    ISuperToken public immutable SPIRIT;

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @notice Name of the vestedSPIRIT Token
    string public name;

    /// @notice Symbol of the vestedSPIRIT Token
    string public symbol;

    /// @notice Decimals of the vestedSPIRIT Token
    uint256 public decimals;

    /// @notice Treasury address
    address public treasury;

    /// @notice Mapping of recipient addresses to their corresponding SPIRIT Token Vesting contract
    mapping(address recipient => address spiritVesting) public spiritVestings;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice SpiritVestingFactory contract constructor
     * @param vestingScheduler The Superfluid vesting scheduler contract
     * @param token The SPIRIT token contract
     * @param treasuryAddress The treasury address
     */
    constructor(IVestingSchedulerV3 vestingScheduler, ISuperToken token, address treasuryAddress) {
        // Persist state variables
        VESTING_SCHEDULER = vestingScheduler;
        SPIRIT = token;
        treasury = treasuryAddress;
        name = "Vested SPIRIT Token";
        symbol = "vestedSPIRIT";
        decimals = 18;
    }

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /// @inheritdoc ISpiritVestingFactory
    function createSpiritVestingContract(
        address recipient,
        uint256 amount,
        uint256 cliffAmount,
        uint32 cliffDate,
        uint32 endDate
    ) external onlyTreasury returns (address newSpiritVestingContract) {
        // Prevent cliff amount from being greater than the total amount
        if (!(cliffAmount < amount)) revert FORBIDDEN();

        // Prevent creation of multiple vesting contracts for the same recipient
        if (spiritVestings[recipient] != address(0)) revert RECIPIENT_ALREADY_HAS_VESTING_CONTRACT();

        uint256 vestingDuration = endDate - cliffDate;

        uint256 vestingAmount = amount - cliffAmount;
        int96 flowRate = int256(vestingAmount / vestingDuration).toInt96();

        // Add the remainder to the cliff amount
        cliffAmount += vestingAmount - (uint96(flowRate) * vestingDuration);

        // Deploy the new SPIRIT Token Vesting contract
        newSpiritVestingContract =
            address(new SpiritVesting(VESTING_SCHEDULER, SPIRIT, recipient, cliffDate, flowRate, cliffAmount, endDate));

        // Maps the recipient address to the new SPIRIT Token Vesting contract
        spiritVestings[recipient] = newSpiritVestingContract;

        // Transfer the tokens from the treasury to the new vesting contract
        SPIRIT.transferFrom(msg.sender, newSpiritVestingContract, amount);

        // Emit the events
        emit Transfer(address(0), recipient, amount);
        emit SpiritVestingCreated(recipient, newSpiritVestingContract);
    }

    /// @inheritdoc ISpiritVestingFactory
    function setTreasury(address newTreasury) external onlyTreasury {
        // Ensure the new treasury address is not the zero address
        if (newTreasury == address(0)) revert FORBIDDEN();
        treasury = newTreasury;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /// @inheritdoc ISpiritVestingFactory
    function balanceOf(address vestingReceiver) public view returns (uint256 unvestedBalance) {
        // Get the flow buffer amount
        (,, uint256 deposit,) = SPIRIT.getFlowInfo(spiritVestings[vestingReceiver], vestingReceiver);

        unvestedBalance += SPIRIT.balanceOf(spiritVestings[vestingReceiver]) + deposit;
    }

    //      __  ___          ___ _____
    //     /  |/  /___  ____/ (_) __(_)__  __________
    //    / /|_/ / __ \/ __  / / /_/ / _ \/ ___/ ___/
    //   / /  / / /_/ / /_/ / / __/ /  __/ /  (__  )
    //  /_/  /_/\____/\__,_/_/_/ /_/\___/_/  /____/

    /**
     * @notice Modifier to restrict access to treasury only
     */
    modifier onlyTreasury() {
        if (msg.sender != treasury) revert FORBIDDEN();
        _;
    }

}
