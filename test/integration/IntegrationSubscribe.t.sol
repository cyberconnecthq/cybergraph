// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";
import { Soul } from "../../src/core/Soul.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { Subscribe } from "../../src/core/Subscribe.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { LibString } from "../../src/libraries/LibString.sol";

import "forge-std/console.sol";

contract IntegrationSubscribeTest is TestIntegrationBase {
    address bob = address(0xB0B);
    address alice = address(0xA11CE);
    address charles = address(0xC);
    uint256 initBalance = 100 ether;

    function setUp() public {
        _setUp();
        Soul(addrs.soul).createSoul(bob, true);
        Soul(addrs.soul).createSoul(alice, false);
        Soul(addrs.soul).createSoul(charles, false);
        vm.deal(bob, initBalance);
        vm.deal(alice, initBalance);
    }

    /* solhint-disable func-name-mixedcase */

    function test_RegisterSubscriptionWithWrongParams_Revert() public {
        vm.startPrank(alice);
        vm.expectRevert("EMPTY_NAME");
        CyberEngine(addrs.engine).registerSubscription(
            DataTypes.RegisterSubscriptionParams(
                alice,
                "",
                "AFAN",
                "https://example.com/afan",
                30,
                1 ether,
                alice
            )
        );

        vm.expectRevert("EMPTY_SYMBOL");
        CyberEngine(addrs.engine).registerSubscription(
            DataTypes.RegisterSubscriptionParams(
                alice,
                "alice's fan",
                "",
                "https://example.com/afan",
                30,
                1 ether,
                alice
            )
        );

        vm.expectRevert("INVALID_PRICE_PER_SUB");
        CyberEngine(addrs.engine).registerSubscription(
            DataTypes.RegisterSubscriptionParams(
                alice,
                "alice's fan",
                "AFAN",
                "https://example.com/afan",
                30,
                0,
                alice
            )
        );

        vm.expectRevert("INVALID_DAY_PER_SUB");
        CyberEngine(addrs.engine).registerSubscription(
            DataTypes.RegisterSubscriptionParams(
                alice,
                "alice's fan",
                "AFAN",
                "https://example.com/afan",
                0,
                1 ether,
                alice
            )
        );

        vm.expectRevert("ZERO_RECIPIENT_ADDRESS");
        CyberEngine(addrs.engine).registerSubscription(
            DataTypes.RegisterSubscriptionParams(
                alice,
                "alice's fan",
                "AFAN",
                "https://example.com/afan",
                30,
                1 ether,
                address(0)
            )
        );
    }

    function test_RegisterSubscription() public {
        vm.startPrank(alice);
        string memory tokenURI = "https://example.com/afan";
        uint256 pricePerSub = 1 ether;
        uint256 dayPerSub = 30;
        CyberEngine(addrs.engine).registerSubscription(
            DataTypes.RegisterSubscriptionParams(
                alice,
                "alice's fan",
                "AFAN",
                tokenURI,
                dayPerSub,
                pricePerSub,
                alice
            )
        );

        assertEq(
            CyberEngine(addrs.engine).getSubscriptionTokenURI(alice),
            tokenURI
        );
        assertEq(
            CyberEngine(addrs.engine).getSubscriptionPricePerSub(alice),
            pricePerSub
        );
        assertEq(
            CyberEngine(addrs.engine).getSubscriptionDayPerSub(alice),
            dayPerSub
        );
        assertEq(
            CyberEngine(addrs.engine).getSubscriptionRecipient(alice),
            alice
        );
    }

    function test_SubscriptionRegistered_RegisterSubscriptionAgain_Revert()
        public
    {
        vm.startPrank(alice);
        CyberEngine(addrs.engine).registerSubscription(
            DataTypes.RegisterSubscriptionParams(
                alice,
                "alice's fan",
                "AFAN",
                "https://example.com/afan",
                30,
                1 ether,
                alice
            )
        );

        vm.expectRevert("ALREADY_REGISTERED");
        CyberEngine(addrs.engine).registerSubscription(
            DataTypes.RegisterSubscriptionParams(
                alice,
                "alice's fan",
                "AFAN",
                "https://example.com/afan",
                30,
                1 ether,
                alice
            )
        );
    }

    function test_SubscriptionRegistered_SetSubscriptionData_Success() public {
        vm.startPrank(alice);
        CyberEngine(addrs.engine).registerSubscription(
            DataTypes.RegisterSubscriptionParams(
                alice,
                "alice's fan",
                "AFAN",
                "https://example.com/afan",
                30,
                1 ether,
                alice
            )
        );

        CyberEngine(addrs.engine).setSubscriptionData(
            alice,
            "https://example.com/afan/v2",
            bob,
            2 ether,
            1
        );
        assertEq(
            CyberEngine(addrs.engine).getSubscriptionTokenURI(alice),
            "https://example.com/afan/v2"
        );
        assertEq(
            CyberEngine(addrs.engine).getSubscriptionPricePerSub(alice),
            2 ether
        );
        assertEq(CyberEngine(addrs.engine).getSubscriptionDayPerSub(alice), 1);
        assertEq(
            CyberEngine(addrs.engine).getSubscriptionRecipient(alice),
            bob
        );
    }

    function test_SubscriptionNotRegistered_Subscribe_Revert() public {
        vm.prank(bob);
        vm.expectRevert("SUBSCRIBE_DOES_NOT_EXIST");
        CyberEngine(addrs.engine).subscribe(alice, bob);
    }

    function test_SubscribeWithNotEnoughFee_Revert() public {
        vm.prank(alice);
        CyberEngine(addrs.engine).registerSubscription(
            DataTypes.RegisterSubscriptionParams(
                alice,
                "alice's fan",
                "AFAN",
                "https://example.com/afan",
                30,
                1 ether,
                alice
            )
        );

        vm.prank(bob);
        vm.expectRevert("FEE_NOT_ENOUGH");
        CyberEngine(addrs.engine).subscribe{ value: 1 ether - 1 wei }(
            alice,
            bob
        );
    }

    function test_SubscribeWithEnoughFee_Success() public {
        vm.prank(alice);
        CyberEngine(addrs.engine).registerSubscription(
            DataTypes.RegisterSubscriptionParams(
                alice,
                "alice's fan",
                "AFAN",
                "https://example.com/afan",
                30,
                1 ether,
                alice
            )
        );

        vm.startPrank(bob);
        uint256 tokenId = CyberEngine(addrs.engine).subscribe{ value: 1 ether }(
            alice,
            bob
        );
        assertEq(bob.balance, initBalance - 1 ether);
        assertEq(alice.balance, initBalance + 1 ether);
        address subAddr = CyberEngine(addrs.engine).getSubscriptionAddr(alice);
        assertEq(Subscribe(subAddr).ownerOf(tokenId), bob);
        assertEq(
            Subscribe(subAddr).expiries(tokenId),
            block.timestamp + 30 days
        );
        assertEq(Subscribe(subAddr).ownedToken(bob), tokenId);

        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        Subscribe(subAddr).transferFrom(bob, alice, tokenId);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        Subscribe(subAddr).safeTransferFrom(bob, alice, tokenId);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        Subscribe(subAddr).safeTransferFrom(bob, alice, tokenId, "");

        assertEq(
            Subscribe(subAddr).tokenURI(tokenId),
            string(
                abi.encodePacked(
                    "https://example.com/afan",
                    LibString.toString(tokenId)
                )
            )
        );
    }

    function test_SubscribeWithOverPayment_SuccessWithRefund() public {
        vm.prank(alice);
        CyberEngine(addrs.engine).registerSubscription(
            DataTypes.RegisterSubscriptionParams(
                alice,
                "alice's fan",
                "AFAN",
                "https://example.com/afan",
                30,
                1 ether,
                alice
            )
        );

        vm.startPrank(bob);
        uint256 tokenId = CyberEngine(addrs.engine).subscribe{
            value: 2 ether + 1 wei
        }(alice, bob);
        assertEq(bob.balance, initBalance - 2 ether);
        assertEq(alice.balance, initBalance + 2 ether);
        address subAddr = CyberEngine(addrs.engine).getSubscriptionAddr(alice);
        assertEq(Subscribe(subAddr).ownerOf(tokenId), bob);
        assertEq(
            Subscribe(subAddr).expiries(tokenId),
            block.timestamp + 2 * 30 days
        );
        assertEq(Subscribe(subAddr).ownedToken(bob), tokenId);
    }

    function test_Subscribed_SubscribeAgain_Success() public {
        vm.prank(alice);
        CyberEngine(addrs.engine).registerSubscription(
            DataTypes.RegisterSubscriptionParams(
                alice,
                "alice's fan",
                "AFAN",
                "https://example.com/afan",
                30,
                1 ether,
                alice
            )
        );

        vm.startPrank(bob);
        CyberEngine(addrs.engine).subscribe{ value: 1 ether }(alice, bob);
        uint256 tokenId = CyberEngine(addrs.engine).subscribe{ value: 1 ether }(
            alice,
            bob
        );
        assertEq(bob.balance, initBalance - 2 ether);
        assertEq(alice.balance, initBalance + 2 ether);
        address subAddr = CyberEngine(addrs.engine).getSubscriptionAddr(alice);
        assertEq(Subscribe(subAddr).ownerOf(tokenId), bob);
        assertEq(
            Subscribe(subAddr).expiries(tokenId),
            block.timestamp + 2 * 30 days
        );
        assertEq(Subscribe(subAddr).ownedToken(bob), tokenId);
    }

    function test_SubscribeExpired_SubscribeAgain_Success() public {
        vm.prank(alice);
        CyberEngine(addrs.engine).registerSubscription(
            DataTypes.RegisterSubscriptionParams(
                alice,
                "alice's fan",
                "AFAN",
                "https://example.com/afan",
                30,
                1 ether,
                alice
            )
        );

        vm.startPrank(bob);
        CyberEngine(addrs.engine).subscribe{ value: 1 ether }(alice, bob);

        uint256 currentTs = block.timestamp + 90 days;
        vm.warp(currentTs);

        uint256 tokenId = CyberEngine(addrs.engine).subscribe{ value: 1 ether }(
            alice,
            bob
        );
        assertEq(bob.balance, initBalance - 2 ether);
        assertEq(alice.balance, initBalance + 2 ether);
        address subAddr = CyberEngine(addrs.engine).getSubscriptionAddr(alice);
        assertEq(Subscribe(subAddr).ownerOf(tokenId), bob);
        assertEq(Subscribe(subAddr).expiries(tokenId), currentTs + 30 days);
        assertEq(Subscribe(subAddr).ownedToken(bob), tokenId);
    }

    /* solhint-disable func-name-mixedcase */
}
