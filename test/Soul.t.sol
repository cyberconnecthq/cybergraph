// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Soul } from "../src/core/Soul.sol";

import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "forge-std/console.sol";
import "forge-std/Test.sol";

contract SoulTest is Test {
    address public soulOwner = address(0x1);
    address public alice = address(0x2);
    address public bob = address(0x3);
    address public soulProxy;

    function setUp() public {
        Soul soulImpl = new Soul();
        soulProxy = address(
            new ERC1967Proxy(
                address(soulImpl),
                abi.encodeWithSelector(
                    Soul.initialize.selector,
                    soulOwner,
                    "soul",
                    "SOUL"
                )
            )
        );
    }

    function testInitialize() public {
        Soul soulImpl = new Soul();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(soulImpl),
            abi.encodeWithSelector(
                Soul.initialize.selector,
                soulOwner,
                "soul",
                "SOUL"
            )
        );

        assertEq(Soul(address(proxy)).owner(), soulOwner);
        assertEq(Soul(address(proxy)).name(), "soul");
        assertEq(Soul(address(proxy)).symbol(), "SOUL");
    }

    function testCreateNonOrgSoul() public {
        vm.prank(soulOwner);
        Soul(soulProxy).createSoul(alice, false);
        assertEq(Soul(soulProxy).ownerOf(0), alice);
        assertFalse(Soul(soulProxy).isOrgAccount(alice));
    }

    function testCreateOrgSoul() public {
        vm.prank(soulOwner);
        Soul(soulProxy).createSoul(alice, true);
        assertEq(Soul(soulProxy).ownerOf(0), alice);
        assertTrue(Soul(soulProxy).isOrgAccount(alice));
    }

    function testPromoteToOrg() public {
        vm.prank(soulOwner);
        Soul(soulProxy).createSoul(alice, false);
        assertEq(Soul(soulProxy).ownerOf(0), alice);
        assertFalse(Soul(soulProxy).isOrgAccount(alice));

        vm.prank(soulOwner);
        Soul(soulProxy).setOrg(alice, true);
        assertTrue(Soul(soulProxy).isOrgAccount(alice));
    }

    function testOrgDegrade() public {
        vm.prank(soulOwner);
        Soul(soulProxy).createSoul(alice, true);
        assertEq(Soul(soulProxy).ownerOf(0), alice);
        assertTrue(Soul(soulProxy).isOrgAccount(alice));

        vm.prank(soulOwner);
        Soul(soulProxy).setOrg(alice, false);
        assertFalse(Soul(soulProxy).isOrgAccount(alice));
    }

    function testSoulCannotTransfer() public {
        vm.prank(soulOwner);
        Soul(soulProxy).createSoul(alice, false);

        vm.prank(alice);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        Soul(soulProxy).transferFrom(alice, bob, 0);

        vm.prank(alice);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        Soul(soulProxy).safeTransferFrom(alice, bob, 0);

        vm.prank(alice);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        Soul(soulProxy).safeTransferFrom(alice, bob, 0, "");
    }

    function testGetTokenURI() public {
        vm.prank(soulOwner);
        Soul(soulProxy).createSoul(alice, false);

        assertEq(Soul(soulProxy).tokenURI(0), "0");

        vm.expectRevert("NOT_MINTED");
        assertEq(Soul(soulProxy).tokenURI(1), "");
    }
}
