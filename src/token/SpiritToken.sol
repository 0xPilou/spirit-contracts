pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { CustomSuperTokenBase } from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/CustomSuperTokenBase.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";
import { ISuperTokenFactory } from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperTokenFactory.sol";
import { UUPSProxy } from "@superfluid-finance/ethereum-contracts/contracts/upgradability/UUPSProxy.sol";

contract SpiritToken is CustomSuperTokenBase, UUPSProxy {

    function initialize(
        ISuperTokenFactory factory,
        string memory name,
        string memory symbol,
        address receiver,
        uint256 initialSupply
    ) external {
        // This call to the factory invokes `UUPSProxy.initialize`, which connects the proxy to the canonical SuperToken
        // implementation.
        // It also emits an event which facilitates discovery of this token.
        ISuperTokenFactory(factory).initializeCustomSuperToken(address(this));

        // This initializes the token storage and sets the `initialized` flag of OpenZeppelin Initializable.
        // This makes sure that it will revert if invoked more than once.
        ISuperToken(address(this)).initialize(IERC20(address(0)), 18, name, symbol);

        // This mints the specified initial supply to the specified receiver.
        ISuperToken(address(this)).selfMint(receiver, initialSupply, "");
    }

}
