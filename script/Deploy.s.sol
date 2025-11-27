// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/* Local imports */
import { SpiritDeployer } from "script/SpiritDeployer.sol";
import { NetworkConfig } from "script/config/NetworkConfig.sol";

/* Foundry imports */
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

contract DeploySpirit is Script {

    function _startBroadcast() internal returns (address deployer) {
        vm.startBroadcast();

        (, deployer,) = vm.readCallers();
    }

    function _stopBroadcast() internal {
        vm.stopBroadcast();
    }

    function run() external {
        uint256 chainId = block.chainid;

        // Get Base mainnet configuration
        NetworkConfig.SpiritDeploymentConfig memory config = NetworkConfig.getNetworkConfig(chainId);

        console.log("");
        console.log("===> DEPLOYMENT CONFIGURATION");
        console.log(" --- Admin address                 :", config.admin);
        console.log(" --- Treasury address              :", config.treasury);
        console.log(" --- Distributor address           :", config.distributor);
        console.log(" --- Super Token Factory           :", config.superTokenFactory);
        console.log(" --- UniswapV4 Position Manager    :", config.positionManager);
        console.log(" --- UniswapV4 Pool Manager        :", config.poolManager);
        console.log(" --- Permit2 address               :", config.permit2);
        console.log(" --- Spirit Token Name             :", config.spiritTokenName);
        console.log(" --- Spirit Token Symbol           :", config.spiritTokenSymbol);
        console.log(" --- Spirit Token Supply           :", config.spiritTokenSupply / 1e18);
        console.log(" --- SPIRIT/ETH Initial Tick       :", config.spiritInitialTick);
        console.log(" --- SPIRIT/ETH Tick Spacing       :", config.spiritTickSpacing);
        console.log(" --- SPIRIT/ETH Pool Fee           :", config.spiritPoolFee);

        // Start broadcasting transactions
        address deployer = _startBroadcast();
        console.log("");
        console.log("===> DEPLOYING SPIRIT PROTOCOL");
        console.log(" --- Chain ID          :   ", chainId);
        console.log(" --- Deployer address  :   ", deployer);
        console.log(" --- Deployer balance  :   ", deployer.balance / 1e18, "ETH");

        // Deploy Spirit Protocol
        SpiritDeployer.SpiritDeploymentResult memory result = SpiritDeployer.deployAll(config, deployer);

        _stopBroadcast();

        console.log("");
        console.log("===> DEPLOYMENT RESULTS");
        console.log(" --- Spirit Token              :", result.spirit);
        console.log(" --- Reward Controller         :", result.rewardControllerProxy);
        console.log(" --- Staking Pool              :", result.stakingPoolBeacon);
        console.log(" --- Spirit Factory              :", result.spiritFactoryProxy);
        console.log(" --- Spirit Vesting Factory    :", result.spiritVestingFactory);
        console.log("");
    }

}
