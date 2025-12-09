// SPDX-License-Identifier: AGPLv3
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

interface IAirstream {

    function owner() external view returns (address);
    function pause() external;
    function unpause() external;
    function distributionToken() external view returns (address);
    function pool() external view returns (address);
    function flowRate() external view returns (int96);
    function redirectRewards(address[] memory from, address[] memory to, uint256[] memory amounts) external;
    function withdraw(address token) external;
    function claim(address account, uint256 amount, bytes32[] calldata proof) external;
    function getAllocation(address account) external view returns (uint256);

}
