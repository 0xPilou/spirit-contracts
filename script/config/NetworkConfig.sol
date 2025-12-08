// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library NetworkConfig {

    struct SpiritDeploymentConfig {
        // Role Settings
        address admin;
        address treasury;
        address distributor;
        // External Contracts Settings
        address vestingScheduler;
        address superTokenFactory;
        address positionManager;
        address poolManager;
        address permit2;
        address airstreamFactory;
        // SPIRIT Token & Liquidity Settings
        string spiritTokenName;
        string spiritTokenSymbol;
        uint256 spiritTokenSupply;
        uint256 spiritTokenLiquiditySupply;
        uint24 spiritPoolFee;
        int24 spiritInitialTick;
        int24 spiritTickSpacing;
    }

    function getNetworkConfig(uint256 chainId) internal pure returns (SpiritDeploymentConfig memory config) {
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
    function getBaseMainnetConfig() internal pure returns (SpiritDeploymentConfig memory) {
        return SpiritDeploymentConfig({
            admin: address(0),
            treasury: address(0),
            distributor: address(0),
            vestingScheduler: 0x6Bf35A170056eDf9aEba159dce4a640cfCef9312,
            superTokenFactory: 0xe20B9a38E0c96F61d1bA6b42a61512D56Fea1Eb3,
            positionManager: 0x7C5f5A4bBd8fD63184577525326123B519429bDc,
            poolManager: 0x498581fF718922c3f8e6A244956aF099B2652b2b,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            airstreamFactory: 0xAB82062c4A9E4DF736238bcfA9fea15eb763bf69,
            spiritTokenName: "Spirit Token",
            spiritTokenSymbol: "SPIRIT",
            spiritTokenSupply: 1_000_000_000 ether,
            spiritTokenLiquiditySupply: 250_000_000 ether,
            spiritInitialTick: 184_200,
            spiritPoolFee: 10_000,
            spiritTickSpacing: 200
        });
    }

    function getLocalConfig() internal pure returns (SpiritDeploymentConfig memory) {
        return getBaseMainnetConfig();
    }

    /**
     * @dev Get Base Sepolia configuration
     */
    function getBaseSepoliaConfig() internal pure returns (SpiritDeploymentConfig memory) {
        return SpiritDeploymentConfig({
            admin: 0x5D6D8518A1d564c85ea5c41d1dc0deca70F2301C,
            treasury: 0x5D6D8518A1d564c85ea5c41d1dc0deca70F2301C,
            distributor: 0x5D6D8518A1d564c85ea5c41d1dc0deca70F2301C,
            vestingScheduler: 0x2D0B7a30bFdED086571D6525762a809ee1049c98,
            superTokenFactory: 0x7447E94Dfe3d804a9f46Bf12838d467c912C8F6C,
            positionManager: 0x4B2C77d209D3405F41a037Ec6c77F7F5b8e2ca80,
            poolManager: 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            airstreamFactory: 0x0000000000000000000000000000000000000000, // Airstreams not available on Base Sepolia
            spiritTokenName: "Secret Token V3",
            spiritTokenSymbol: "SECRETv3",
            spiritTokenSupply: 1_000_000_000 ether,
            spiritTokenLiquiditySupply: 250_000_000 ether,
            spiritInitialTick: 184_200,
            spiritPoolFee: 10_000,
            spiritTickSpacing: 200
        });
    }

    /**
     * @dev Get Ethereum Sepolia configuration
     */
    function getEthereumSepoliaConfig() internal pure returns (SpiritDeploymentConfig memory) {
        return SpiritDeploymentConfig({
            admin: 0x5D6D8518A1d564c85ea5c41d1dc0deca70F2301C,
            treasury: 0x5D6D8518A1d564c85ea5c41d1dc0deca70F2301C,
            distributor: 0x5D6D8518A1d564c85ea5c41d1dc0deca70F2301C,
            vestingScheduler: 0x638a8ABF60118e018c80a0eC878057E8C53E0fd1,
            positionManager: 0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4,
            poolManager: 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            airstreamFactory: 0x0652b67bE172579055FE4D04e715566D78Ad43c8,
            superTokenFactory: 0x254C2e152E8602839D288A7bccdf3d0974597193,
            spiritTokenName: "Secret Token V3",
            spiritTokenSymbol: "SECRETv3",
            spiritTokenSupply: 1_000_000_000 ether,
            spiritTokenLiquiditySupply: 250_000_000 ether,
            spiritInitialTick: 184_200,
            spiritPoolFee: 10_000,
            spiritTickSpacing: 200
        });
    }

}
