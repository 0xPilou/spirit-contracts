pragma solidity ^0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    AirstreamConfig,
    AirstreamExtendedConfig,
    ClaimingWindow,
    IAirstreamFactory
} from "src/interfaces/external/IAirstreamFactory.sol";

contract AirstreamFactoryMock {

    function createExtendedAirstream(AirstreamConfig memory config, AirstreamExtendedConfig memory)
        public
        returns (address airstreamAddress, address controllerAddress)
    {
        IERC20(config.token).transferFrom(msg.sender, address(this), config.totalAmount);
    }

}
