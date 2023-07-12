// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { TokenReceiver } from "../src/periphery/TokenReceiver.sol";

import "forge-std/console.sol";
import "forge-std/Test.sol";

contract TokenReceiverTest is Test {
    address public owner = address(0x1);
    address public alice = address(0x2);
    address public bob = address(0x3);

    TokenReceiver tr;

    function setUp() public {
        tr = new TokenReceiver(owner);
    }

    /* solhint-disable func-name-mixedcase */
    function testDeposit() public {
        hoax(alice, 10 ether);
        require(alice.balance == 10 ether, "WRONG_BAL");

        tr.depositTo{ value: 1 ether }(bob);

        require(alice.balance == 9 ether, "WRONG_BAL");
        require(tr.getDepositBalance(bob) == 1 ether, "WRONG_DEPOSIT");
        require(tr.getDepositBalance(alice) == 0 ether, "WRONG_DEPOSIT");
    }

    function testWithdraw() public {
        hoax(alice, 10 ether);
        tr.depositTo{ value: 5 ether }(bob);

        require(address(tr).balance == 5 ether, "WRONG_BAL");

        vm.prank(owner);
        tr.withdraw(bob, 1 ether);

        require(address(tr).balance == 4 ether, "WRONG_BAL");
        require(bob.balance == 1 ether, "WRONG_BAL");
        require(tr.getDepositBalance(bob) == 5 ether, "WRONG_DEPOSIT");
    }

    function testWithdrawNotOwner() public {
        hoax(alice, 10 ether);
        tr.depositTo{ value: 5 ether }(bob);

        vm.expectRevert("UNAUTHORIZED");
        tr.withdraw(bob, 1 ether);
    }

    /* solhint-disable func-name-mixedcase */
}
