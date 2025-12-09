// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title SPIRIT Token Vesting Factory Contract Interface
 * @notice Contract deploying new SPIRIT Token Vesting contracts
 */
interface ISpiritVestingFactory {

    //      ______                 __
    //     / ____/   _____  ____  / /______
    //    / __/ | | / / _ \/ __ \/ __/ ___/
    //   / /___ | |/ /  __/ / / / /_(__  )
    //  /_____/ |___/\___/_/ /_/\__/____/

    /// @notice Event emitted when a new SPIRIT token vesting contract is created
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice Event emitted when a new SPIRIT token vesting contract is created
    event SpiritVestingCreated(address indexed recipient, address indexed newSpiritVestingContract);

    //     ______           __                     ______
    //    / ____/_  _______/ /_____  ____ ___     / ____/_____________  __________
    //   / /   / / / / ___/ __/ __ \/ __ `__ \   / __/ / ___/ ___/ __ \/ ___/ ___/
    //  / /___/ /_/ (__  ) /_/ /_/ / / / / / /  / /___/ /  / /  / /_/ / /  (__  )
    //  \____/\__,_/____/\__/\____/_/ /_/ /_/  /_____/_/  /_/   \____/_/  /____/

    /// @notice Error thrown when the caller is not the foundation treasury
    error FORBIDDEN();

    /// @notice Error thrown when a recipient already has a vesting contract at the given vesting index
    error RECIPIENT_ALREADY_HAS_VESTING_CONTRACT();



    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Creates a SPIRIT token vesting contract for a recipient
     * @param recipient The address that will receive the vested tokens
     * @param amount The total amount of SPIRIT tokens to be vested
     * @param cliffAmount The amount of SPIRIT tokens that will be transferred at cliff date
     * @param cliffDate The timestamp when the cliff period ends and the flow can start
     * @param endDate The timestamp when the vesting schedule ends
     * @return newSpiritVestingContract The address of the newly created vesting contract
     */
    function createSpiritVestingContract(
        address recipient,
        uint256 amount,
        uint256 cliffAmount,
        uint32 cliffDate,
        uint32 endDate
    ) external returns (address newSpiritVestingContract);

    /**
     * @notice Updates the treasury address
     * @param newTreasury The new treasury address to set
     * @dev Can only be called by the treasury itself
     */
    function setTreasury(address newTreasury) external;

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Gets the unvested token balance of a given vesting receiver
     * @param vestingReceiver The address of the vesting receiver to query
     * @return unvestedBalance The sum of the vesting contract's token balance and the pending flow deposits
     */
    function balanceOf(address vestingReceiver) external view returns (uint256 unvestedBalance);

    /**
     * @notice Gets the treasury address
     * @return treasury The current treasury address
     */
    function treasury() external view returns (address treasury);

}
