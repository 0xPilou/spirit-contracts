// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Deployers } from "@uniswap/v4-core/test/utils/Deployers.sol";
import { PositionManager } from "@uniswap/v4-periphery/src/PositionManager.sol";
import { IPositionDescriptor } from "@uniswap/v4-periphery/src/interfaces/IPositionDescriptor.sol";
import { IPositionManager } from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import { IWETH9 } from "@uniswap/v4-periphery/src/interfaces/external/IWETH9.sol";

import { DeployPermit2 } from "./DeployPermit2.sol";

contract UniswapDeployer is Deployers, DeployPermit2 {

    IPositionManager internal positionManager;

    // Using production limit
    // https://basescan.org/address/0x7c5f5a4bbd8fd63184577525326123b519429bdc#readContract
    // 22. unsubscribeGasLimit (0x4767565f)
    uint256 internal UNSUBSCRIBE_GAS_LIMIT = 300_000;

    function setUp() public virtual {
        // Uniswap Protocol Deployment Start
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();
        deployPositionManager();
        // Uniswap Protocol Deployment End
    }

    function deployPositionManager() internal {
        // We use vm.etch to prevent having to use via-ir in this repository.
        etchPermit2();
        positionManager = IPositionManager(
            new PositionManager(
                manager, permit2, UNSUBSCRIBE_GAS_LIMIT, IPositionDescriptor(address(0)), IWETH9(address(0))
            )
        );
    }

}
