// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";
import { MockERC20 } from "../utils/MockERC20.sol";
import { Soul } from "../../src/core/Soul.sol";
import { LimitedTimePaidMw } from "../../src/middlewares/LimitedTimePaidMw.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { MiddlewareManager } from "../../src/core/MiddlewareManager.sol";
import { Treasury } from "../../src/middlewares/base/Treasury.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";

import "forge-std/console.sol";

contract LimitedTimePaidMwTest is TestIntegrationBase {
    address public mw;
    address public mockToken;
    address public alice = address(0xa11ce);
    address public bob = address(0xb0b);
    address public charlie = address(0xca);

    string constant BOB_ISSUED_1_URL = "mf.com";

    function setUp() public {
        _setUp();
        Soul(addrs.soul).createSoul(alice, false);
        Soul(addrs.soul).createSoul(bob, false);
        mw = address(
            new LimitedTimePaidMw(addrs.cyberTreasury, addrs.engine, addrs.soul)
        );
        mockToken = address(new MockERC20());
        vm.prank(protocolOwner);
        Treasury(addrs.cyberTreasury).allowCurrency(mockToken, true);
        vm.prank(protocolOwner);
        MiddlewareManager(addrs.manager).allowMw(address(mw), true);
    }

    /* solhint-disable func-name-mixedcase */

    function testSetMwWithInvalidParams() public {
        vm.startPrank(alice);
        vm.expectRevert("INVALID_RECIPENT");
        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(
                uint256(100),
                uint256(1 ether),
                address(0),
                mockToken,
                uint256(1786564834),
                uint256(0),
                // 10%
                uint16(1000),
                false
            )
        );

        vm.expectRevert("INVALID_TOTAL_SUPPLY");
        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(
                uint256(0),
                uint256(1 ether),
                alice,
                mockToken,
                uint256(1786564834),
                uint256(0),
                // 10%
                uint16(1000),
                false
            )
        );

        vm.expectRevert("INVALID_PRICE");
        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(
                uint256(100),
                uint256(0),
                alice,
                mockToken,
                uint256(1786564834),
                uint256(0),
                // 10%
                uint16(1000),
                false
            )
        );

        vm.expectRevert("INVALID_TIME_RANGE");
        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(
                uint256(100),
                uint256(1 ether),
                alice,
                mockToken,
                uint256(1786564834),
                uint256(1786564834),
                // 10%
                uint16(1000),
                false
            )
        );

        vm.expectRevert("CURRENCY_NOT_ALLOWED");
        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(
                uint256(100),
                uint256(1 ether),
                alice,
                address(123456),
                uint256(1786564834),
                uint256(0),
                // 10%
                uint16(1000),
                false
            )
        );

        vm.expectRevert("INVALID_REFERRAL_FEE");
        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(
                uint256(100),
                uint256(1 ether),
                alice,
                mockToken,
                uint256(1786564834),
                uint256(0),
                uint16(10001),
                false
            )
        );
    }

    function testSetMwData() public {
        vm.prank(alice);
        uint256 tokenId = CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(
                uint256(100),
                uint256(1 ether),
                alice,
                mockToken,
                uint256(1786564834),
                uint256(0),
                // 10%
                uint16(1000),
                false
            )
        );
        assertEq(tokenId, 0);
    }

    function test_MwSet_CollectContent_Success() public {
        vm.prank(alice);
        uint256 tokenId = CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(
                uint256(100),
                uint256(1 ether),
                alice,
                mockToken,
                uint256(1786564834),
                uint256(0),
                // 10%
                uint16(1000),
                true
            )
        );

        vm.startPrank(bob);
        MockERC20(mockToken).mint(bob, 1 ether);
        MockERC20(mockToken).approve(mw, 1 ether);
        uint256 mintedId = CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                alice,
                tokenId,
                1,
                bob,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
        assertEq(mintedId, 0);
        assertEq(MockERC20(mockToken).balanceOf(bob), 0);
        assertEq(
            MockERC20(mockToken).balanceOf(alice),
            _mulPercentage(1 ether, 9750)
        );
        assertEq(
            MockERC20(mockToken).balanceOf(treasuryReceiver),
            _mulPercentage(1 ether, 250)
        );
    }

    function test_MwSet_CollectContentExceedsLimite_Revert() public {
        vm.prank(alice);
        uint256 tokenId = CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(
                uint256(1),
                uint256(1 ether),
                alice,
                mockToken,
                uint256(1786564834),
                uint256(0),
                // 10%
                uint16(1000),
                true
            )
        );

        vm.startPrank(bob);
        MockERC20(mockToken).mint(bob, 2 ether);
        MockERC20(mockToken).approve(mw, 2 ether);
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                alice,
                tokenId,
                1,
                bob,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );

        vm.expectRevert("COLLECT_LIMIT_EXCEEDED");
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                alice,
                tokenId,
                1,
                bob,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
    }

    function test_MwSet_CollectContentInInavlidTimeRange_Revert() public {
        vm.prank(alice);
        uint256 tokenId = CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(
                uint256(1),
                uint256(1 ether),
                alice,
                mockToken,
                uint256(60),
                uint256(2),
                // 10%
                uint16(1000),
                true
            )
        );

        vm.startPrank(bob);
        MockERC20(mockToken).mint(bob, 2 ether);
        MockERC20(mockToken).approve(mw, 2 ether);
        vm.expectRevert("NOT_STARTED");
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                alice,
                tokenId,
                1,
                bob,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );

        vm.warp(61);
        vm.expectRevert("ENDED");
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                alice,
                tokenId,
                1,
                bob,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
    }

    function test_MwSet_CollectMoreThanOne_Revert() public {
        vm.startPrank(alice);
        uint256 tokenId = CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(
                uint256(1),
                uint256(1 ether),
                alice,
                mockToken,
                uint256(60),
                uint256(0),
                // 10%
                uint16(1000),
                true
            )
        );
        vm.expectRevert("INCORRECT_COLLECT_AMOUNT");
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                alice,
                tokenId,
                2,
                alice,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
    }

    function test_MwSet_CollectContentNonSoulOwner_Revert() public {
        vm.prank(alice);
        uint256 tokenId = CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(
                uint256(1),
                uint256(1 ether),
                alice,
                mockToken,
                uint256(60),
                uint256(0),
                // 10%
                uint16(1000),
                true
            )
        );
        vm.startPrank(charlie);
        vm.expectRevert("NOT_SOUL_OWNER");
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                alice,
                tokenId,
                1,
                charlie,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
    }

    function test_MwSetWithReferralFee_CollectShare_Success() public {
        vm.prank(alice);
        uint256 tokenId = CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(
                uint256(1),
                uint256(1 ether),
                alice,
                mockToken,
                uint256(60),
                uint256(0),
                // 10%
                uint16(1000),
                false
            )
        );

        vm.prank(bob);
        uint256 shareTokenId = CyberEngine(addrs.engine).share(
            DataTypes.ShareParams(bob, alice, tokenId)
        );

        vm.startPrank(charlie);
        MockERC20(mockToken).mint(charlie, 1 ether);
        MockERC20(mockToken).approve(mw, 1 ether);
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                bob,
                shareTokenId,
                1,
                charlie,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
        assertEq(MockERC20(mockToken).balanceOf(charlie), 0);
        assertEq(
            MockERC20(mockToken).balanceOf(bob),
            _mulPercentage(_mulPercentage(1 ether, 9750), 1000)
        );
        assertEq(
            MockERC20(mockToken).balanceOf(alice),
            _mulPercentage(_mulPercentage(1 ether, 9750), 9000)
        );
        assertEq(
            MockERC20(mockToken).balanceOf(treasuryReceiver),
            _mulPercentage(1 ether, 250)
        );
    }

    function _mulPercentage(
        uint256 num,
        uint256 bps
    ) internal pure returns (uint256) {
        return (num * bps) / 10000;
    }
    /* solhint-disable func-name-mixedcase */
}
