// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin-v5/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin-v5/contracts/token/ERC721/IERC721.sol";

import { SafeCast } from "@openzeppelin-v5/contracts/utils/math/SafeCast.sol";
import { SuperTokenV1Library } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";

import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { ISuperfluidPool } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import { SpiritDeployer } from "script/SpiritDeployer.sol";
import { NetworkConfig } from "script/config/NetworkConfig.sol";
import { RewardController } from "src/core/RewardController.sol";
import { SpiritFactory } from "src/factory/SpiritFactory.sol";
import { IStakingPool } from "src/interfaces/core/IStakingPool.sol";
import { IAirstream } from "src/interfaces/external/IAirstream.sol";

import { SpiritVestingFactory } from "src/vesting/SpiritVestingFactory.sol";
import { SpiritTestBase } from "test/base/SpiritTestBase.t.sol";

using SafeCast for int256;
using SuperTokenV1Library for ISuperToken;

contract AirstreamIntegrationForkTest is SpiritTestBase {

    struct MerkleDetails {
        uint256 amount;
        bytes32[] proof;
    }

    NetworkConfig.SpiritDeploymentConfig internal _config;

    address public user1;
    address public user2;
    address public user3;
    address public user4;

    /**
     * Merkle Root Created from the following Merkle Tree:
     * ```
     * "receivers": [
     *     [ "0x48CA32c738DC2Af6cE8bB33934fF1b59cF8B1831", "100000000000000000000000000"  ],
     *     [ "0x301933aEf6bB308f090087e9075ed5bFcBd3e0B3", "75000000000000000000000000" ],
     *     [ "0x1F0Ec748dc3994629e32Eb1223a52D5aE8E8f90e", "50000000000000000000000000" ],
     *     [ "0x18CCC193FeBDAf93A2C5e24E306E72a77012C429", "25000000000000000000000000" ]
     * ]
     * ```
     */
    bytes32 public constant MERKLE_ROOT = 0x8d4663416110726abbf3aa614fa42b05988a07030b995dd0f07d3cd36fdcd851;

    mapping(address receiver => MerkleDetails details) internal _merkleDetails;

    function setUp() public override {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 39_210_000);

        _config = NetworkConfig.getNetworkConfig(8453);

        _config.admin = ADMIN;
        _config.distributor = ADMIN;
        _config.treasury = TREASURY;

        // Deploy the contracts under test
        vm.startPrank(DEPLOYER);
        SpiritDeployer.SpiritDeploymentResult memory result = SpiritDeployer.deployAll(_config, DEPLOYER);
        vm.stopPrank();

        _spiritFactory = SpiritFactory(result.spiritFactoryProxy);
        _rewardController = RewardController(result.rewardControllerProxy);
        _spiritVestingFactory = SpiritVestingFactory(result.spiritVestingFactory);
        _spirit = ISuperToken(result.spirit);

        user1 = 0x48CA32c738DC2Af6cE8bB33934fF1b59cF8B1831;
        user2 = 0x301933aEf6bB308f090087e9075ed5bFcBd3e0B3;
        user3 = 0x1F0Ec748dc3994629e32Eb1223a52D5aE8E8f90e;
        user4 = 0x18CCC193FeBDAf93A2C5e24E306E72a77012C429;

        // Populate the merkle details for testing purpose
        _helper_populateTestData();
    }

    function _createChild()
        internal
        returns (
            ISuperToken newChildToken,
            IStakingPool newStakingPool,
            address airstreamAddress,
            address controllerAddress
        )
    {
        bytes32 salt = keccak256(abi.encode("SALT_FOR_NEW_CHILD_TOKEN"));

        vm.prank(ADMIN);
        (newChildToken, newStakingPool, airstreamAddress, controllerAddress) = _spiritFactory.createChild(
            "New Child Token", "NEWCHILD", ARTIST, AGENT, TREASURY, MERKLE_ROOT, salt, DEFAULT_SQRT_PRICE_X96
        );

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
            newChildToken.balanceOf(TREASURY),
            _spiritFactory.PLATFORM_ALLOCATION(),
            "Platform (TREASURY) should have 250M CHILD tokens (PLATFORM allocation)"
        );
        assertEq(
            newChildToken.balanceOf(address(newStakingPool)),
            _spiritFactory._ARTIST_AND_AGENT_ALLOCATION(),
            "Staking Pool should have 450M CHILD tokens (ARTIST and AGENT shares)"
        );

        assertEq(
            newChildToken.balanceOf(address(_config.poolManager)),
            _spiritFactory.LIQUIDITY_SUPPLY(),
            "UniswapV4 Pool Manager should have 50M CHILD tokens (Liquidity)"
        );

        assertApproxEqAbs(
            newChildToken.balanceOf(address(controllerAddress)),
            _spiritFactory.AIRSTREAM_SUPPLY(),
            _spiritFactory.AIRSTREAM_SUPPLY() / 1000, // 0.1% tolerance (stream buffer discarded)
            "Airstream Recipient should have 250M CHILD tokens (AIRSTREAM share)"
        );

        assertEq(
            IERC721(address(_config.positionManager)).balanceOf(address(AGENT)),
            1,
            "AGENT should own 1 UniswapV4 Position NFT"
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
            newStakingPool.calculateMultiplier(newStakingPool.STAKEHOLDER_LOCKING_PERIOD()) * 200_000_000
                / newStakingPool.MIN_MULTIPLIER(),
            "AGENT should have 200M CHILD tokens locked for 12 months worth of units"
        );
    }

    function test_createChild() public {
        _createChild();
    }

    function test_claimAirstream() public {
        (ISuperToken newChildToken,, address airstreamAddress,) = _createChild();

        int96 expectedFlowRate1 = int256(_merkleDetails[user1].amount / _spiritFactory.AIRSTREAM_DURATION()).toInt96();

        IAirstream(airstreamAddress).claim(user1, _merkleDetails[user1].amount, _merkleDetails[user1].proof);

        assertApproxEqAbs(
            int256(newChildToken.getFlowRate(IAirstream(airstreamAddress).pool(), user1)),
            int256(expectedFlowRate1),
            uint256(int256(expectedFlowRate1 * 100 / 10_000)), // allow 1% error tolerance
            "Flow rate mismatch"
        );

        int96 expectedFlowRate2 = int256(_merkleDetails[user2].amount / _spiritFactory.AIRSTREAM_DURATION()).toInt96();

        IAirstream(airstreamAddress).claim(user2, _merkleDetails[user2].amount, _merkleDetails[user2].proof);

        assertApproxEqAbs(
            int256(newChildToken.getFlowRate(IAirstream(airstreamAddress).pool(), user2)),
            int256(expectedFlowRate2),
            uint256(int256(expectedFlowRate2 * 100 / 10_000)), // allow 1% error tolerance
            "Flow rate mismatch"
        );

        int96 expectedFlowRate3 = int256(_merkleDetails[user3].amount / _spiritFactory.AIRSTREAM_DURATION()).toInt96();

        IAirstream(airstreamAddress).claim(user3, _merkleDetails[user3].amount, _merkleDetails[user3].proof);

        assertApproxEqAbs(
            int256(newChildToken.getFlowRate(IAirstream(airstreamAddress).pool(), user3)),
            int256(expectedFlowRate3),
            uint256(int256(expectedFlowRate3 * 100 / 10_000)), // allow 1% error tolerance
            "Flow rate mismatch"
        );

        int96 expectedFlowRate4 = int256(_merkleDetails[user4].amount / _spiritFactory.AIRSTREAM_DURATION()).toInt96();

        IAirstream(airstreamAddress).claim(user4, _merkleDetails[user4].amount, _merkleDetails[user4].proof);

        assertApproxEqAbs(
            int256(newChildToken.getFlowRate(IAirstream(airstreamAddress).pool(), user4)),
            int256(expectedFlowRate4),
            uint256(int256(expectedFlowRate4 * 100 / 10_000)), // allow 1% error tolerance
            "Flow rate mismatch"
        );
    }

    function test_terminateAirstream() public {
        (ISuperToken newChildToken,, address airstreamAddress,) = _createChild();

        IAirstream(airstreamAddress).claim(user1, _merkleDetails[user1].amount, _merkleDetails[user1].proof);
        IAirstream(airstreamAddress).claim(user2, _merkleDetails[user2].amount, _merkleDetails[user2].proof);
        IAirstream(airstreamAddress).claim(user3, _merkleDetails[user3].amount, _merkleDetails[user3].proof);
        IAirstream(airstreamAddress).claim(user4, _merkleDetails[user4].amount, _merkleDetails[user4].proof);

        vm.startPrank(user1);
        newChildToken.connectPool(ISuperfluidPool(IAirstream(airstreamAddress).pool()));
        vm.stopPrank();

        vm.startPrank(user2);
        newChildToken.connectPool(ISuperfluidPool(IAirstream(airstreamAddress).pool()));
        vm.stopPrank();

        vm.startPrank(user3);
        newChildToken.connectPool(ISuperfluidPool(IAirstream(airstreamAddress).pool()));
        vm.stopPrank();

        vm.startPrank(user4);
        newChildToken.connectPool(ISuperfluidPool(IAirstream(airstreamAddress).pool()));
        vm.stopPrank();

        vm.warp(block.timestamp + _spiritFactory.AIRSTREAM_DURATION());
        vm.prank(ADMIN);
        _spiritFactory.terminateAirstream(address(newChildToken));

        assertApproxEqAbs(
            newChildToken.balanceOf(user1),
            _merkleDetails[user1].amount,
            _merkleDetails[user1].amount / 1000, // allow 0.1% error tolerance
            "Balance mismatch"
        );
        assertApproxEqAbs(
            newChildToken.balanceOf(user2),
            _merkleDetails[user2].amount,
            _merkleDetails[user2].amount / 1000, // allow 0.1% error tolerance
            "Balance mismatch"
        );
        assertApproxEqAbs(
            newChildToken.balanceOf(user3),
            _merkleDetails[user3].amount,
            _merkleDetails[user3].amount / 1000, // allow 0.1% error tolerance
            "Balance mismatch"
        );
        assertApproxEqAbs(
            newChildToken.balanceOf(user4),
            _merkleDetails[user4].amount,
            _merkleDetails[user4].amount / 1000, // allow 0.1% error tolerance
            "Balance mismatch"
        );
        assertEq(newChildToken.getFlowRate(IAirstream(airstreamAddress).pool(), user1), 0);
        assertEq(newChildToken.getFlowRate(IAirstream(airstreamAddress).pool(), user2), 0);
        assertEq(newChildToken.getFlowRate(IAirstream(airstreamAddress).pool(), user3), 0);
        assertEq(newChildToken.getFlowRate(IAirstream(airstreamAddress).pool(), user4), 0);
    }

    function _helper_populateTestData() internal {
        bytes32[] memory proof1 = new bytes32[](2);
        proof1[0] = 0x15fc854da05710f16d18cca74cc89c9980ea0b3e40983a3f0988e73c616d71a7;
        proof1[1] = 0x01c64e627486e9564a1b80a1e148035bc28544b2eb1e2e3154c1fb1731a068d7;
        _merkleDetails[user1] = MerkleDetails({ amount: 100_000_000 ether, proof: proof1 });

        bytes32[] memory proof2 = new bytes32[](2);
        proof2[0] = 0x5bf20928056c98115262ed271f5a969bcf66e747e618ec3842bb586d0d11dee9;
        proof2[1] = 0x01c64e627486e9564a1b80a1e148035bc28544b2eb1e2e3154c1fb1731a068d7;
        _merkleDetails[user2] = MerkleDetails({ amount: 75_000_000 ether, proof: proof2 });

        bytes32[] memory proof3 = new bytes32[](2);
        proof3[0] = 0xd29a04367b5bc9f90c4fe6812284792c4421fc63f622154a05db764a2630b717;
        proof3[1] = 0x249ed1e1d273ffb05bceff43bc50f7de317a14345da9e93cef1a64bb679804d7;
        _merkleDetails[user3] = MerkleDetails({ amount: 50_000_000 ether, proof: proof3 });

        bytes32[] memory proof4 = new bytes32[](2);
        proof4[0] = 0x7f5e5f7738c0b01d96d98b04c532e91837df84f460bd4be3e4a86af5aae30d39;
        proof4[1] = 0x249ed1e1d273ffb05bceff43bc50f7de317a14345da9e93cef1a64bb679804d7;
        _merkleDetails[user4] = MerkleDetails({ amount: 25_000_000 ether, proof: proof4 });
    }

}
