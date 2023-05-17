// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { CyberAccount } from "../src/core/CyberAccount.sol";

contract CyberAccountTest is Test {
    CyberAccount ca;

    function setUp() public {
        ca = CyberAccount(payable(address(0x11)));
    }

    function testBasic() public {
        assertEq(true, true);
    }
}
