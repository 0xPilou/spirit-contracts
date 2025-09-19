pragma solidity ^0.8.26;

import { IStakingPool } from "src/interfaces/core/IStakingPool.sol";

interface IRewardController {

    // ERRORS
    error STAKING_POOL_ALREADY_SET();
    error STAKING_POOL_NOT_FOUND();
    error INVALID_CHILD();
    error INVALID_AMOUNT();

    // EXTERNAL FUNCTIONS
    function setStakingPool(address child, IStakingPool stakingPool) external;
    function distributeRewards(address child, uint256 amount) external;

}
