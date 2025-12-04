// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IERC721 } from "@openzeppelin-v5/contracts/token/ERC721/IERC721.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IStakingPool } from "src/interfaces/core/IStakingPool.sol";

import { ISpiritFactory } from "src/interfaces/factory/ISpiritFactory.sol";
import { SpiritTestBase } from "test/base/SpiritTestBase.t.sol";

import { IHooks } from "@uniswap/v4-core/src/interfaces/IHooks.sol";

import { Currency } from "@uniswap/v4-core/src/types/Currency.sol";
import { PoolKey } from "@uniswap/v4-core/src/types/PoolKey.sol";
import { ChildSuperToken } from "src/token/ChildSuperToken.sol";

contract SpiritFactoryTest is SpiritTestBase {

    uint160 internal constant MALICIOUS_SQRT_PRICE_X96 = 250_541_448_375_047_946_302_209_916_928;

    function setUp() public override {
        super.setUp();
    }

    function test_initialize() public view {
        assertTrue(
            _spiritFactory.hasRole(_spiritFactory.DEFAULT_ADMIN_ROLE(), ADMIN), "ADMIN does not have DEFAULT_ADMIN_ROLE"
        );
    }

    function _createChild(uint256 specialAllocation)
        internal
        returns (ISuperToken newChildToken, IStakingPool newStakingPool)
    {
        vm.prank(ADMIN);
        if (specialAllocation == 0) {
            (newChildToken, newStakingPool) = _spiritFactory.createChild(
                "New Child Token", "NEWCHILD", ARTIST, AGENT, bytes32(0), DEFAULT_SQRT_PRICE_X96
            );
        } else {
            (newChildToken, newStakingPool) = _spiritFactory.createChild(
                "New Child Token", "NEWCHILD", ARTIST, AGENT, specialAllocation, bytes32(0), DEFAULT_SQRT_PRICE_X96
            );
        }

        // State settings assertions
        assertNotEq(address(newChildToken), address(0), "Invalid child token address");
        assertNotEq(address(newStakingPool), address(0), "Invalid staking pool address");
        assertEq(address(newStakingPool.child()), address(newChildToken), "Child token mismatch");
        assertEq(address(newStakingPool.SPIRIT()), address(_spirit), "SPIRIT token mismatch");
        assertEq(address(newStakingPool.REWARD_CONTROLLER()), address(_rewardController), "Reward controller mismatch");
        assertEq(
            address(_rewardController.stakingPools(address(newChildToken))),
            address(newStakingPool),
            "Staking pool mismatch"
        );

        // Token Supply Assertions
        assertEq(newChildToken.totalSupply(), _spiritFactory.CHILD_TOTAL_SUPPLY(), "Invalid minted supply");
        assertEq(newChildToken.balanceOf(ARTIST), 0, "Artist should not have floating CHILD tokens");
        assertEq(newChildToken.balanceOf(AGENT), 0, "Agent should not have floating CHILD tokens");
        assertEq(
            newChildToken.balanceOf(address(newStakingPool)),
            500_000_000 ether,
            "Staking Pool should have 500M CHILD tokens (ARTIST and AGENT shares)"
        );

        assertEq(
            newChildToken.balanceOf(address(manager)),
            _spiritFactory.DEFAULT_LIQUIDITY_SUPPLY() - specialAllocation,
            "UniswapV4 Pool Manager should have 250M CHILD tokens (Liquidity)"
        );

        assertEq(
            newChildToken.balanceOf(address(_airstreamFactory)),
            _spiritFactory.AIRSTREAM_SUPPLY(),
            "Airstream Recipient should have 250M CHILD tokens (AIRSTREAM share)"
        );

        assertEq(
            newChildToken.balanceOf(address(ADMIN)),
            specialAllocation,
            "Admin should have `specialAllocation` CHILD tokens (ADMIN share)"
        );

        assertEq(
            IERC721(address(positionManager)).balanceOf(address(ADMIN)), 1, "ADMIN should own 1 UniswapV4 Position NFT"
        );

        // GDA Settings Assertions
        assertEq(
            newStakingPool.distributionPool().getUnits(address(newStakingPool)), 1, "Distribution pool units mismatch"
        );
        assertEq(
            newStakingPool.distributionPool().getUnits(address(ARTIST)),
            newStakingPool.calculateMultiplier(newStakingPool.STAKEHOLDER_LOCKING_PERIOD()) * 250_000_000
                / newStakingPool.MIN_MULTIPLIER(),
            "ARTIST should have 250M CHILD tokens locked for 12 months worth of units"
        );
        assertEq(
            newStakingPool.distributionPool().getUnits(address(AGENT)),
            newStakingPool.calculateMultiplier(newStakingPool.STAKEHOLDER_LOCKING_PERIOD()) * 250_000_000
                / newStakingPool.MIN_MULTIPLIER(),
            "AGENT should have 250M CHILD tokens locked for 12 months worth of units"
        );
    }

    function test_createChild() public {
        _createChild(0);
    }

    function test_createChild_with_special_allocation(uint256 specialAllocation) public {
        specialAllocation = bound(specialAllocation, 1, _spiritFactory.DEFAULT_LIQUIDITY_SUPPLY() - 1);

        _createChild(specialAllocation);
    }

    function test_createChild_invalid_caller(address nonAdmin) public {
        vm.assume(_spiritFactory.hasRole(_spiritFactory.DEFAULT_ADMIN_ROLE(), nonAdmin) != true);

        vm.prank(nonAdmin);
        vm.expectRevert();
        _spiritFactory.createChild("New Child Token", "NEWCHILD", ARTIST, AGENT, bytes32(0), DEFAULT_SQRT_PRICE_X96);
    }

    function test_createChild_invalid_special_allocation(uint256 specialAllocation) public {
        specialAllocation =
            bound(specialAllocation, _spiritFactory.DEFAULT_LIQUIDITY_SUPPLY(), _spiritFactory.CHILD_TOTAL_SUPPLY());

        vm.prank(ADMIN);
        vm.expectRevert(ISpiritFactory.INVALID_SPECIAL_ALLOCATION.selector);
        _spiritFactory.createChild(
            "New Child Token", "NEWCHILD", ARTIST, AGENT, specialAllocation, bytes32(0), DEFAULT_SQRT_PRICE_X96
        );
    }

    function test_createChild_invalid_poolAlreadyInitialized() public {
        // Simulate a malicious actor "guessing" a child token address and initializing the pool with it

        // Predict the child token address
        address predictedChildTokenAddress = _helper_predictChildTokenAddress("New Child Token", "NEWCHILD");

        // Maliciously initalize the pool with predicted child token address
        Currency currency0 = predictedChildTokenAddress < address(_spirit)
            ? Currency.wrap(address(predictedChildTokenAddress))
            : Currency.wrap(address(_spirit));
        Currency currency1 = predictedChildTokenAddress > address(_spirit)
            ? Currency.wrap(address(predictedChildTokenAddress))
            : Currency.wrap(address(_spirit));

        // Create the pool key
        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 10_000,
            tickSpacing: 200,
            hooks: IHooks(address(0))
        });

        // Initialize the pool
        positionManager.initializePool(poolKey, MALICIOUS_SQRT_PRICE_X96);

        vm.prank(ADMIN);
        vm.expectRevert(ISpiritFactory.POOL_INITIALIZATION_FAILED.selector);
        _spiritFactory.createChild("New Child Token", "NEWCHILD", ARTIST, AGENT, bytes32(0), DEFAULT_SQRT_PRICE_X96);
    }

    function _helper_predictChildTokenAddress(string memory name, string memory symbol)
        internal
        view
        returns (address predicted)
    {
        bytes32 salt = keccak256(abi.encode(name, symbol));
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(_spiritFactory), salt, keccak256(type(ChildSuperToken).creationCode))
        );
        return address(uint160(uint256(hash)));
    }

}
