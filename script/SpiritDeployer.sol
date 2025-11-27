// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/* Openzeppelin Imports */
import { ERC1967Proxy } from "@openzeppelin-v5/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UpgradeableBeacon } from "@openzeppelin-v5/contracts/proxy/beacon/UpgradeableBeacon.sol";

/* Superfluid Imports */
import { IVestingSchedulerV3 } from
    "@superfluid-finance/automation-contracts/scheduler/contracts/interface/IVestingSchedulerV3.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";
import { ISuperTokenFactory } from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperTokenFactory.sol";

/* Uniswap Imports */
import { IHooks } from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import { IPoolManager } from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import { StateLibrary } from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import { TickMath } from "@uniswap/v4-core/src/libraries/TickMath.sol";
import { CurrencyLibrary } from "@uniswap/v4-core/src/types/Currency.sol";
import { Currency } from "@uniswap/v4-core/src/types/Currency.sol";
import { PoolIdLibrary } from "@uniswap/v4-core/src/types/PoolId.sol";
import { PoolKey } from "@uniswap/v4-core/src/types/PoolKey.sol";
import { IPermit2 } from "@uniswap/v4-periphery/lib/permit2/src/interfaces/IPermit2.sol";
import { IPositionManager } from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import { Actions } from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import { LiquidityAmounts } from "@uniswap/v4-periphery/src/libraries/LiquidityAmounts.sol";

/* Local Imports */
import { NetworkConfig } from "script/config/NetworkConfig.sol";
import { RewardController } from "src/core/RewardController.sol";
import { StakingPool } from "src/core/StakingPool.sol";
import { SpiritFactory } from "src/factory/SpiritFactory.sol";
import { IRewardController } from "src/interfaces/core/IRewardController.sol";
import { IAirstreamFactory } from "src/interfaces/external/IAirstreamFactory.sol";
import { ISpiritToken } from "src/interfaces/token/ISpiritToken.sol";
import { SpiritToken } from "src/token/SpiritToken.sol";
import { SpiritVesting } from "src/vesting/SpiritVesting.sol";
import { SpiritVestingFactory } from "src/vesting/SpiritVestingFactory.sol";

library SpiritDeployer {

    struct SpiritDeploymentResult {
        address spirit;
        address rewardControllerLogic;
        address rewardControllerProxy;
        address stakingPoolLogic;
        address stakingPoolBeacon;
        address spiritFactoryLogic;
        address spiritFactoryProxy;
        address spiritVestingFactory;
        PoolKey spiritEthPoolKey;
    }

    function deployAll(NetworkConfig.SpiritDeploymentConfig memory config, address deployer)
        internal
        returns (SpiritDeploymentResult memory results)
    {
        // Contracts Deployment

        // Deploy the Spirit Token Contract
        results = _deploySpiritToken(config, deployer);

        // Deploy the Spirit Vesting Factory Contract
        results = _deployVestingFactory(config, results);

        // Setup UniswapV4 SPIRIT/ETH pool
        results = _setupUniswapPool(config, results);

        // Mint the liquidity position for the SPIRIT/ETH pool
        _deployLiquidity(config, results);

        /// FIXME: Create Vesting For Team (?)
        /// FIXME: Create Vesting For Ops (?)

        // Transfer the SPIRIT Tokens to the Treasury
        ISuperToken(results.spirit).transfer(config.treasury, ISuperToken(results.spirit).balanceOf(deployer));

        // Deploy the Infrastructure Contracts
        results = _deployInfrastructure(config, results);

        // Contracts Configuration
        RewardController rc = RewardController(results.rewardControllerProxy);
        rc.grantRole(rc.FACTORY_ROLE(), address(results.spiritFactoryProxy));
        rc.revokeRole(rc.DEFAULT_ADMIN_ROLE(), deployer);
    }

    function _deploySpiritToken(NetworkConfig.SpiritDeploymentConfig memory config, address deployer)
        internal
        returns (SpiritDeploymentResult memory results)
    {
        results.spirit = address(new SpiritToken());

        // Initialize the new SpiritToken contract
        ISpiritToken(results.spirit).initialize(
            ISuperTokenFactory(config.superTokenFactory),
            config.spiritTokenName,
            config.spiritTokenSymbol,
            deployer,
            config.spiritTokenSupply
        );
    }

    function _deployVestingFactory(
        NetworkConfig.SpiritDeploymentConfig memory config,
        SpiritDeploymentResult memory results
    ) internal returns (SpiritDeploymentResult memory) {
        // Deploy the Spirit Vesting Factory Contract
        SpiritVestingFactory vestingFactory = new SpiritVestingFactory(
            IVestingSchedulerV3(config.vestingScheduler), ISuperToken(results.spirit), config.treasury
        );

        // Deploy an unused SpiritVesting contract for explorer verification purposes
        new SpiritVesting(
            IVestingSchedulerV3(config.vestingScheduler),
            ISuperToken(results.spirit),
            config.treasury,
            uint32(block.timestamp + 1000 weeks),
            1,
            1,
            uint32(block.timestamp + 2000 weeks)
        );

        results.spiritVestingFactory = address(vestingFactory);

        return results;
    }

    function _deployInfrastructure(
        NetworkConfig.SpiritDeploymentConfig memory config,
        SpiritDeploymentResult memory results
    ) internal returns (SpiritDeploymentResult memory) {
        // Deploy the Reward Controller contract
        RewardController rewardControllerLogic = new RewardController(ISuperToken(results.spirit));
        ERC1967Proxy rewardControllerProxy = new ERC1967Proxy(
            address(rewardControllerLogic), abi.encodeWithSelector(RewardController.initialize.selector, config.admin)
        );

        // Deploy the Staking Pool Beacon contract
        address stakingPoolLogicAddress =
            address(new StakingPool(ISuperToken(results.spirit), address(rewardControllerProxy)));
        UpgradeableBeacon stakingPoolBeacon = new UpgradeableBeacon(stakingPoolLogicAddress, config.admin);

        // Deploy the Spirit Factory contract
        SpiritFactory spiritFactoryLogic = new SpiritFactory(
            address(stakingPoolBeacon),
            ISuperToken(results.spirit),
            IRewardController(address(rewardControllerProxy)),
            ISuperTokenFactory(config.superTokenFactory),
            IPositionManager(config.positionManager),
            IPoolManager(config.poolManager),
            IPermit2(config.permit2),
            IAirstreamFactory(config.airstreamFactory)
        );
        ERC1967Proxy spiritFactoryProxy = new ERC1967Proxy(
            address(spiritFactoryLogic), abi.encodeWithSelector(SpiritFactory.initialize.selector, config.admin)
        );

        results.rewardControllerLogic = address(rewardControllerLogic);
        results.rewardControllerProxy = address(rewardControllerProxy);
        results.stakingPoolBeacon = address(stakingPoolBeacon);
        results.stakingPoolLogic = address(stakingPoolLogicAddress);
        results.spiritFactoryLogic = address(spiritFactoryLogic);
        results.spiritFactoryProxy = address(spiritFactoryProxy);

        return results;
    }

    /// LIQUIDITY SETUP FUNCTIONS
    function _setupUniswapPool(
        NetworkConfig.SpiritDeploymentConfig memory config,
        SpiritDeploymentResult memory results
    ) internal returns (SpiritDeploymentResult memory) {
        // Create the pool key
        results.spiritEthPoolKey = PoolKey({
            currency0: CurrencyLibrary.ADDRESS_ZERO,
            currency1: Currency.wrap(results.spirit),
            fee: config.spiritPoolFee,
            tickSpacing: config.spiritTickSpacing,
            hooks: IHooks(address(0))
        });

        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(config.spiritInitialTick);

        // Initialize the pool
        IPositionManager(config.positionManager).initializePool(results.spiritEthPoolKey, sqrtPriceX96);

        return results;
    }

    function _deployLiquidity(NetworkConfig.SpiritDeploymentConfig memory config, SpiritDeploymentResult memory results)
        internal
    {
        (uint256 amount0, uint256 amount1, uint128 liquidity, int24 tickLower, int24 tickUpper) =
            _orderParams(config, results.spirit, config.spiritTokenLiquiditySupply, results.spiritEthPoolKey);

        bytes memory actions = new bytes(2);
        actions[0] = bytes1(uint8(Actions.MINT_POSITION));
        actions[1] = bytes1(uint8(Actions.SETTLE_PAIR));

        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(
            results.spiritEthPoolKey, tickLower, tickUpper, liquidity, amount0, amount1, config.treasury, bytes("")
        );
        params[1] = abi.encode(results.spiritEthPoolKey.currency0, results.spiritEthPoolKey.currency1);

        _approvePermit2(config, results.spirit, config.spiritTokenLiquiditySupply);

        // Execute the minting transaction
        IPositionManager(config.positionManager).modifyLiquidities(abi.encode(actions, params), block.timestamp + 60);
    }

    function _orderParams(
        NetworkConfig.SpiritDeploymentConfig memory config,
        address spiritToken,
        uint256 spiritTokenAmount,
        PoolKey memory poolKey
    ) internal view returns (uint256 amount0, uint256 amount1, uint128 liquidity, int24 tickLower, int24 tickUpper) {
        bool spiritIsZero = poolKey.currency0 == Currency.wrap(spiritToken);

        // Calculate the liquidity based on provided amounts and current price
        (uint160 sqrtPriceX96, int24 tick,,) =
            StateLibrary.getSlot0(IPoolManager(config.poolManager), PoolIdLibrary.toId(poolKey));

        if (spiritIsZero) {
            amount0 = spiritTokenAmount;
            amount1 = 0;
            tickLower = tick;
            tickUpper = (TickMath.MAX_TICK / config.spiritTickSpacing) * config.spiritTickSpacing;
        } else {
            amount0 = 0;
            amount1 = spiritTokenAmount;
            tickLower = (TickMath.MIN_TICK / config.spiritTickSpacing) * config.spiritTickSpacing;
            tickUpper = tick;
        }

        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            amount0,
            amount1
        );
    }

    function _approvePermit2(NetworkConfig.SpiritDeploymentConfig memory config, address spiritToken, uint256 amount)
        internal
    {
        // Approve token for spending via Permit2
        ISuperToken(spiritToken).approve(config.permit2, amount);
        IPermit2(config.permit2).approve(
            spiritToken, address(config.positionManager), uint160(amount), uint48(block.timestamp + 60)
        );
    }

}
