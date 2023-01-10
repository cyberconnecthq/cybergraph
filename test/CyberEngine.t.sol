// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { CyberWallet } from "../src/core/CyberWallet.sol";

contract CyberWalletTest is Test {
    CyberWallet cw;

    function setUp() public {
        cw = CyberWallet(address(0x11));
    }

    function testBasic() public {
        assertEq(true, true);
    }
}
