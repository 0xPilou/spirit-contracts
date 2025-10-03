// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library NetworkConfig {

    struct EdenDeploymentConfig {
        // Role Settings
        address admin;
        address treasury;
        address distributor;
        // External Contracts Settings
        address superTokenFactory;
        address positionManager;
        address poolManager;
        address permit2;
        address weth;
        // SPIRIT Token & Liquidity Settings
        string spiritTokenName;
        string spiritTokenSymbol;
        uint256 spiritTokenSupply;
        uint256 spiritTokenLiquiditySupply;
        uint24 spiritPoolFee;
        int24 spiritInitialTick;
        int24 spiritTickSpacing;
    }

    function getNetworkConfig(uint256 chainId) internal pure returns (EdenDeploymentConfig memory config) {
        if (chainId == 8453) {
            config = getBaseMainnetConfig();
        } else if (chainId == 84_532) {
            config = getBaseSepoliaConfig();
        } else if (chainId == 11_155_111) {
            config = getEthereumSepoliaConfig();
        } else {
            revert("Unsupported chainId");
        }
    }

    /**
     * @dev Get Base Mainnet configuration
     */
    function getBaseMainnetConfig() internal pure returns (EdenDeploymentConfig memory) {
        return EdenDeploymentConfig({
            admin: address(0),
            treasury: address(0),
            distributor: address(0),
            superTokenFactory: 0xe20B9a38E0c96F61d1bA6b42a61512D56Fea1Eb3,
            positionManager: 0x7C5f5A4bBd8fD63184577525326123B519429bDc,
            poolManager: 0x498581fF718922c3f8e6A244956aF099B2652b2b,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            weth: 0x4200000000000000000000000000000000000006,
            spiritTokenName: "Spirit Token",
            spiritTokenSymbol: "SPIRIT",
            spiritTokenSupply: 1_000_000_000 ether,
            spiritTokenLiquiditySupply: 250_000_000 ether,
            spiritInitialTick: -230_600,
            spiritPoolFee: 10_000,
            spiritTickSpacing: 200
        });
    }

    function getLocalConfig() internal pure returns (EdenDeploymentConfig memory) {
        return getBaseMainnetConfig();
    }

    /**
     * @dev Get Base Sepolia configuration
     */
    function getBaseSepoliaConfig() internal pure returns (EdenDeploymentConfig memory) {
        return EdenDeploymentConfig({
            admin: 0x3139DB2845810C4DE0727A5D5Aa24146C086eE1A,
            treasury: 0x3139DB2845810C4DE0727A5D5Aa24146C086eE1A,
            distributor: 0x3139DB2845810C4DE0727A5D5Aa24146C086eE1A,
            superTokenFactory: 0x7447E94Dfe3d804a9f46Bf12838d467c912C8F6C,
            positionManager: 0x4B2C77d209D3405F41a037Ec6c77F7F5b8e2ca80,
            poolManager: 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            weth: 0x4200000000000000000000000000000000000006,
            spiritTokenName: "Secret Token",
            spiritTokenSymbol: "SECRET",
            spiritTokenSupply: 1_000_000_000 ether,
            spiritTokenLiquiditySupply: 250_000_000 ether,
            spiritInitialTick: -230_600,
            spiritPoolFee: 10_000,
            spiritTickSpacing: 200
        });
    }

    /**
     * @dev Get Ethereum Sepolia configuration
     */
    function getEthereumSepoliaConfig() internal pure returns (EdenDeploymentConfig memory) {
        return EdenDeploymentConfig({
            admin: 0x3139DB2845810C4DE0727A5D5Aa24146C086eE1A,
            treasury: 0x3139DB2845810C4DE0727A5D5Aa24146C086eE1A,
            distributor: 0x3139DB2845810C4DE0727A5D5Aa24146C086eE1A,
            positionManager: 0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4,
            poolManager: 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            superTokenFactory: 0x254C2e152E8602839D288A7bccdf3d0974597193,
            weth: 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14,
            spiritTokenName: "Secret Token",
            spiritTokenSymbol: "SECRET",
            spiritTokenSupply: 1_000_000_000 ether,
            spiritTokenLiquiditySupply: 250_000_000 ether,
            spiritInitialTick: -230_600,
            spiritPoolFee: 10_000,
            spiritTickSpacing: 200
        });
    }

}
