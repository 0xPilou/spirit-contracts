// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { EdenTestBase } from "test/base/EdenTestBase.t.sol";

contract EdenFactoryTest is EdenTestBase {

    function setUp() public override {
        super.setUp();
    }

    function test_initialize() public view {
        assertTrue(
            _edenFactory.hasRole(_edenFactory.DEFAULT_ADMIN_ROLE(), ADMIN), "ADMIN does not have DEFAULT_ADMIN_ROLE"
        );
    }

    function test_createChild() public { }
    function test_createChild_invalid_caller() public { }

}
