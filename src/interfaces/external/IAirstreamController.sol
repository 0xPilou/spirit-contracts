// SPDX-License-Identifier: AGPLv3
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

interface IAirstreamController {

    /**
     * @notice Pause the airstream
     */
    function pauseAirstream() external;

    /**
     * @notice Withdraw the token from the airstream contract and the controller
     * @dev The airstream contract must be paused
     * @param _token Address of the token to withdraw
     */
    function withdraw(address _token) external;

}
