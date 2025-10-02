pragma solidity ^0.8.26;

/* Openzeppelin Imports */
import { AccessControl } from "@openzeppelin-v5/contracts/access/AccessControl.sol";
import { ERC1967Utils } from "@openzeppelin-v5/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { BeaconProxy } from "@openzeppelin-v5/contracts/proxy/beacon/BeaconProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin-v5/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { Initializable } from "@openzeppelin-v5/contracts/proxy/utils/Initializable.sol";

/* Superfluid Imports */
import { ISuperTokenFactory } from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperTokenFactory.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/* Uniswap Imports */
import { IHooks } from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import { IPoolManager } from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import { StateLibrary } from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import { TickMath } from "@uniswap/v4-core/src/libraries/TickMath.sol";
import { Currency } from "@uniswap/v4-core/src/types/Currency.sol";
import { PoolIdLibrary } from "@uniswap/v4-core/src/types/PoolId.sol";
import { PoolKey } from "@uniswap/v4-core/src/types/PoolKey.sol";
import { IPermit2 } from "@uniswap/v4-periphery/lib/permit2/src/interfaces/IPermit2.sol";
import { IPositionManager } from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import { Actions } from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import { LiquidityAmounts } from "@uniswap/v4-periphery/src/libraries/LiquidityAmounts.sol";

/* Local Imports */
import { IRewardController } from "src/interfaces/core/IRewardController.sol";
import { IStakingPool } from "src/interfaces/core/IStakingPool.sol";
import { IEdenFactory } from "src/interfaces/factory/IEdenFactory.sol";
import { IChildSuperToken } from "src/interfaces/token/IChildSuperToken.sol";
import { ChildSuperToken } from "src/token/ChildSuperToken.sol";

contract EdenFactory is IEdenFactory, Initializable, AccessControl {

    //      ____                          __        __    __        _____ __        __
    //     /  _/___ ___  ____ ___  __  __/ /_____ _/ /_  / /__     / ___// /_____ _/ /____  _____
    //     / // __ `__ \/ __ `__ \/ / / / __/ __ `/ __ \/ / _ \    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   _/ // / / / / / / / / / / /_/ / /_/ /_/ / /_/ / /  __/   ___/ / /_/ /_/ / /_/  __(__  )
    //  /___/_/ /_/ /_/_/ /_/ /_/\__,_/\__/\__,_/_.___/_/\___/   /____/\__/\__,_/\__/\___/____/

    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    ISuperToken public immutable SPIRIT;
    UpgradeableBeacon public immutable STAKING_POOL_BEACON;
    ISuperTokenFactory public immutable SUPER_TOKEN_FACTORY;
    IRewardController public immutable REWARD_CONTROLLER;

    IPositionManager public immutable POSITION_MANAGER;
    IPoolManager public immutable POOL_MANAGER;
    IPermit2 public immutable PERMIT2;

    uint160 public constant SQRT_PRICE_1_1 = 79_228_162_514_264_337_593_543_950_336;

    uint256 public constant DEFAULT_SUPPLY = 1_000_000_000 ether;

    /// FIXME : Confirm this value
    uint24 public constant DEFAULT_POOL_FEE = 10_000;

    /// FIXME : Confirm this value
    int24 public constant DEFAULT_TICK_SPACING = 200;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    constructor(
        address _stakingPoolBeacon,
        IRewardController _rewardController,
        ISuperTokenFactory _superTokenFactory,
        IPositionManager _positionManager,
        IPoolManager _poolManager,
        IPermit2 _permit2
    ) {
        STAKING_POOL_BEACON = UpgradeableBeacon(_stakingPoolBeacon);
        REWARD_CONTROLLER = _rewardController;
        SUPER_TOKEN_FACTORY = _superTokenFactory;
        POSITION_MANAGER = _positionManager;
        POOL_MANAGER = _poolManager;
        PERMIT2 = _permit2;
    }

    function initialize(address admin) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function createChild(string memory name, string memory symbol, address artist, address agent)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (ISuperToken child, IStakingPool stakingPool)
    {
        // deploy the new child token with default 1B supply to the caller (admin)
        child = ISuperToken(_deployToken(name, symbol, DEFAULT_SUPPLY));

        // Deploy a new StakingPool contract associated to the child token
        stakingPool = IStakingPool(_deployStakingPool(address(child), artist, agent));

        // Update the reward controller configuration
        REWARD_CONTROLLER.setStakingPool(address(child), stakingPool);

        // Create the Uniswap V4 pool and mint liquidity position for 475M CHILD (single sided)
        _setupUniswapPool(address(child), 475_000_000 ether, SQRT_PRICE_1_1);

        // Transfer the remaining 500M CHILD to the caller (admin)
        child.transfer(msg.sender, child.balanceOf(address(this)));

        // FIXME : Add event emission here
    }

    function upgradeTo(address newImplementation, bytes calldata data) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC1967Utils.upgradeToAndCall(newImplementation, data);
    }

    //      ____      __                        __   ______                 __  _
    //     /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //     / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function _deployToken(string memory name, string memory symbol, uint256 supply)
        internal
        returns (address childToken)
    {
        // This salt will prevent token with the same name and symbol from being deployed twice
        bytes32 salt = keccak256(abi.encode(name, symbol));

        // Deploy the new ChildSuperToken contract
        childToken = address(new ChildSuperToken{ salt: salt }());

        // Initialize the new ChildSuperToken contract
        IChildSuperToken(childToken).initialize(SUPER_TOKEN_FACTORY, name, symbol, address(this), supply);
    }

    function _deployStakingPool(address childToken, address artist, address agent)
        internal
        returns (address stakingPool)
    {
        // This salt will prevent staking pool with the same child token from being deployed twice
        bytes32 salt = keccak256(abi.encode(childToken));

        // Deploy the new StakingPool contract
        stakingPool = address(new BeaconProxy{ salt: salt }(address(STAKING_POOL_BEACON), ""));

        // Approve the staking pool to spend the 500M CHILD (artist and agent share) from this contract
        ISuperToken(childToken).approve(address(stakingPool), 500_000_000 ether);

        // Initialize the new Locker instance
        IStakingPool(stakingPool).initialize(ISuperToken(childToken), artist, agent);
    }

    /**
     * @notice Initializes the Uniswap V4 pool
     */
    function _setupUniswapPool(address childToken, uint256 childTokenAmount, uint160 initialSqrtPriceX96)
        internal
        returns (uint256 tokenId)
    {
        // Ensure tokens are in the correct order (lower address first)
        Currency currency0 =
            childToken < address(SPIRIT) ? Currency.wrap(address(childToken)) : Currency.wrap(address(SPIRIT));
        Currency currency1 =
            childToken > address(SPIRIT) ? Currency.wrap(address(childToken)) : Currency.wrap(address(SPIRIT));

        // Create the pool key
        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: DEFAULT_POOL_FEE,
            tickSpacing: DEFAULT_TICK_SPACING,
            hooks: IHooks(address(0))
        });

        // Initialize the pool
        POSITION_MANAGER.initializePool(poolKey, initialSqrtPriceX96);

        tokenId = _mintSingleSidedLiquidityPosition(childToken, childTokenAmount, poolKey);
    }

    function _mintSingleSidedLiquidityPosition(address childToken, uint256 childTokenAmount, PoolKey memory poolKey)
        internal
        returns (uint256 tokenId)
    {
        // Store the next token ID before minting
        tokenId = POSITION_MANAGER.nextTokenId();

        (uint256 amount0, uint256 amount1, uint128 liquidity, int24 tickLower, int24 tickUpper) =
            _orderParams(childToken, childTokenAmount, poolKey);

        bytes memory actions = new bytes(2);
        actions[0] = bytes1(uint8(Actions.MINT_POSITION));
        actions[1] = bytes1(uint8(Actions.SETTLE_PAIR));

        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(poolKey, tickLower, tickUpper, liquidity, amount0, amount1, msg.sender, bytes(""));
        params[1] = abi.encode(poolKey.currency0, poolKey.currency1);

        _approvePermit2(childToken, childTokenAmount);

        // Execute the minting transaction
        POSITION_MANAGER.modifyLiquidities(abi.encode(actions, params), block.timestamp + 60);
    }

    function _orderParams(address childToken, uint256 childTokenAmount, PoolKey memory poolKey)
        internal
        view
        returns (uint256 amount0, uint256 amount1, uint128 liquidity, int24 tickLower, int24 tickUpper)
    {
        bool childIsZero = poolKey.currency0 == Currency.wrap(childToken);

        // Calculate the liquidity based on provided amounts and current price
        (uint160 sqrtPriceX96, int24 tick,,) = StateLibrary.getSlot0(POOL_MANAGER, PoolIdLibrary.toId(poolKey));

        if (childIsZero) {
            amount0 = childTokenAmount;
            amount1 = 0;
            tickLower = tick;
            tickUpper = (TickMath.MAX_TICK / DEFAULT_TICK_SPACING) * DEFAULT_TICK_SPACING;
        } else {
            amount0 = 0;
            amount1 = childTokenAmount;
            tickLower = (TickMath.MIN_TICK / DEFAULT_TICK_SPACING) * DEFAULT_TICK_SPACING;
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

    function _approvePermit2(address childToken, uint256 amount) internal {
        // Approve token for spending via Permit2
        ISuperToken(childToken).approve(address(PERMIT2), amount);
        IPermit2(PERMIT2).approve(childToken, address(POSITION_MANAGER), uint160(amount), uint48(block.timestamp + 60));
    }

}
