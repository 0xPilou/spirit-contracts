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
import {
    AirstreamConfig,
    AirstreamExtendedConfig,
    ClaimingWindow,
    IAirstreamFactory
} from "src/interfaces/external/IAirstreamFactory.sol";
import { ISpiritFactory } from "src/interfaces/factory/ISpiritFactory.sol";
import { IChildSuperToken } from "src/interfaces/token/IChildSuperToken.sol";
import { ChildSuperToken } from "src/token/ChildSuperToken.sol";

/**
 * @title SpiritFactory
 * @notice SpiritFactory contract
 * @dev This contract is used to create child tokens and staking pools
 */
contract SpiritFactory is ISpiritFactory, Initializable, AccessControl {

    //      ____                          __        __    __        _____ __        __
    //     /  _/___ ___  ____ ___  __  __/ /_____ _/ /_  / /__     / ___// /_____ _/ /____  _____
    //     / // __ `__ \/ __ `__ \/ / / / __/ __ `/ __ \/ / _ \    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   _/ // / / / / / / / / / / /_/ / /_/ /_/ / /_/ / /  __/   ___/ / /_/ /_/ / /_/  __(__  )
    //  /___/_/ /_/ /_/_/ /_/ /_/\__,_/\__/\__,_/_.___/_/\___/   /____/\__/\__,_/\__/\___/____/

    /// @notice SPIRIT SuperToken distributed as rewards
    ISuperToken public immutable SPIRIT;

    /// @notice beacon for deploying staking pool proxies
    UpgradeableBeacon public immutable STAKING_POOL_BEACON;

    /// @notice SuperToken factory for creating child tokennos
    ISuperTokenFactory public immutable SUPER_TOKEN_FACTORY;

    /// @notice RewardController contract responsible for distributing SPIRIT rewards
    IRewardController public immutable REWARD_CONTROLLER;

    /// @notice Uniswap V4 PositionManager contract
    IPositionManager public immutable POSITION_MANAGER;

    /// @notice Uniswap V4 PoolManager contract
    IPoolManager public immutable POOL_MANAGER;

    /// @notice Permit2 contract address
    IPermit2 public immutable PERMIT2;

    /// @notice AirstreamFactory contract for Airstream distribution
    IAirstreamFactory public immutable AIRSTREAM_FACTORY;

    /// @notice Total supply of each child token (1 billion)
    uint256 public constant CHILD_TOTAL_SUPPLY = 1_000_000_000 ether;

    /// @notice Default amount of tokens supplied to the liquidity pool (250 million)
    uint256 public constant DEFAULT_LIQUIDITY_SUPPLY = 250_000_000 ether;

    /// @notice Amount of tokens reserved for the Airstream (250 million)
    uint96 public constant AIRSTREAM_SUPPLY = 250_000_000 ether;

    /// @notice Duration of the Airstream distribution (52 weeks = 1 year)
    uint64 public constant AIRSTREAM_DURATION = 52 weeks;

    /// @notice Default fee for the created Uniswap pool (1%)
    uint24 public constant DEFAULT_POOL_FEE = 10_000;

    /// @notice Default tick spacing for the created Uniswap pool
    int24 public constant DEFAULT_TICK_SPACING = 200;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice SpiritFactory contract constructor
     * @param _stakingPoolBeacon The beacon for deploying staking pool proxies
     * @param _spirit The SPIRIT SuperToken distributed as rewards
     * @param _rewardController The RewardController contract responsible for distributing SPIRIT rewards
     * @param _superTokenFactory The SuperToken factory for creating child tokens
     * @param _positionManager The Uniswap V4 PositionManager contract
     * @param _poolManager The Uniswap V4 PoolManager contract
     * @param _permit2 The Permit2 contract address
     * @param _airstreamFactory The AirstreamFactory contract for Airstream distribution
     */
    constructor(
        address _stakingPoolBeacon,
        ISuperToken _spirit,
        IRewardController _rewardController,
        ISuperTokenFactory _superTokenFactory,
        IPositionManager _positionManager,
        IPoolManager _poolManager,
        IPermit2 _permit2,
        IAirstreamFactory _airstreamFactory
    ) {
        _disableInitializers();

        STAKING_POOL_BEACON = UpgradeableBeacon(_stakingPoolBeacon);
        SPIRIT = _spirit;
        REWARD_CONTROLLER = _rewardController;
        SUPER_TOKEN_FACTORY = _superTokenFactory;
        POSITION_MANAGER = _positionManager;
        POOL_MANAGER = _poolManager;
        PERMIT2 = _permit2;
        AIRSTREAM_FACTORY = IAirstreamFactory(_airstreamFactory);
    }

    /**
     * @notice Initializes the SpiritFactory contract
     * @param admin The address to grant the DEFAULT_ADMIN_ROLE
     */
    function initialize(address admin) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /// @inheritdoc ISpiritFactory
    function createChild(
        string memory name,
        string memory symbol,
        address artist,
        address agent,
        bytes32 merkleRoot,
        uint160 initialSqrtPriceX96
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (ISuperToken child, IStakingPool stakingPool) {
        (child, stakingPool) = _createChild(name, symbol, artist, agent, 0, merkleRoot, initialSqrtPriceX96);
    }

    /// @inheritdoc ISpiritFactory
    function createChild(
        string memory name,
        string memory symbol,
        address artist,
        address agent,
        uint256 specialAllocation,
        bytes32 merkleRoot,
        uint160 initialSqrtPriceX96
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (ISuperToken child, IStakingPool stakingPool) {
        // Ensure the special allocation is not greater than the default liquidity supply
        if (specialAllocation >= DEFAULT_LIQUIDITY_SUPPLY) revert INVALID_SPECIAL_ALLOCATION();

        (child, stakingPool) =
            _createChild(name, symbol, artist, agent, specialAllocation, merkleRoot, initialSqrtPriceX96);
    }

    /// @inheritdoc ISpiritFactory
    function upgradeTo(address newImplementation, bytes calldata data) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC1967Utils.upgradeToAndCall(newImplementation, data);
    }

    //      ____      __                        __   ______                 __  _
    //     /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //     / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function _createChild(
        string memory name,
        string memory symbol,
        address artist,
        address agent,
        uint256 specialAllocation,
        bytes32 merkleRoot,
        uint160 initialSqrtPriceX96
    ) internal returns (ISuperToken child, IStakingPool stakingPool) {
        // deploy the new child token with default 1B supply to the caller (admin)
        child = ISuperToken(_deployToken(name, symbol, CHILD_TOTAL_SUPPLY));

        // Deploy a new StakingPool contract associated to the child token
        stakingPool = IStakingPool(_deployStakingPool(address(child), artist, agent));

        // Update the reward controller configuration
        REWARD_CONTROLLER.setStakingPool(address(child), stakingPool);

        // Create the Uniswap V4 pool and mint liquidity position for 250M CHILD (single sided)
        _setupUniswapPool(address(child), DEFAULT_LIQUIDITY_SUPPLY - specialAllocation, initialSqrtPriceX96);

        // Deploy the Airstreams
        _deployAirstream(name, address(child), merkleRoot);

        // Transfer the remaining balance (if any) to the caller (admin)
        uint256 remainingBalance = child.balanceOf(address(this));

        if (remainingBalance > 0) {
            child.transfer(msg.sender, remainingBalance);
        }

        emit ChildTokenCreated(address(child), address(stakingPool), artist, agent, merkleRoot);
    }

    function _deployAirstream(string memory name, address childToken, bytes32 merkleRoot) internal {
        AirstreamConfig memory config = AirstreamConfig({
            name: name,
            token: childToken,
            merkleRoot: merkleRoot,
            totalAmount: uint96(AIRSTREAM_SUPPLY),
            duration: AIRSTREAM_DURATION
        });

        AirstreamExtendedConfig memory extendedConfig = AirstreamExtendedConfig({
            superToken: childToken,
            claimingWindow: ClaimingWindow({
                startDate: uint64(block.timestamp),
                duration: AIRSTREAM_DURATION,
                treasury: msg.sender
            }),
            initialRewardPPM: 0,
            feePPM: 0
        });

        ISuperToken(childToken).approve(address(AIRSTREAM_FACTORY), AIRSTREAM_SUPPLY);

        AIRSTREAM_FACTORY.createExtendedAirstream(config, extendedConfig);
    }

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
        int24 currentTick = POSITION_MANAGER.initializePool(poolKey, initialSqrtPriceX96);

        // Ensure the pool was initialized successfully
        if (currentTick == type(int24).max) revert POOL_INITIALIZATION_FAILED();

        // Mint the liquidity position
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
