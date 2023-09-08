// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";
import { LimitedOnlyOnceMw } from "../../src/middlewares/LimitedOnlyOnceMw.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { Soul } from "../../src/core/Soul.sol";
import { MiddlewareManager } from "../../src/core/MiddlewareManager.sol";
import { CyberNFT1155 } from "../../src/base/CyberNFT1155.sol";
import { CyberNFT721 } from "../../src/base/CyberNFT721.sol";

import "forge-std/console.sol";

contract LimitedOnlyOnceMwTest is TestIntegrationBase {
    address public mw;
    uint256 public aliceSk = 666;
    address public alice = vm.addr(aliceSk);
    uint256 public bobSk = 888;
    address public bob = vm.addr(bobSk);

    string constant ALICE_ISSUED_1_URL = "mf.com";

    function setUp() public {
        _setUp();
        Soul(addrs.soul).createSoul(alice, true);
        Soul(addrs.soul).createSoul(bob, false);
        mw = address(new LimitedOnlyOnceMw(addrs.engine));
        vm.prank(protocolOwner);
        MiddlewareManager(addrs.manager).allowMw(address(mw), true);
    }

    /* solhint-disable func-name-mixedcase */

    function testSetMwWithInvalidParams() public {
        vm.startPrank(alice);
        vm.expectRevert("INVALID_TOTAL_SUPPLY");
        CyberEngine(addrs.engine).issueW3st(
            DataTypes.IssueW3stParams(alice, ALICE_ISSUED_1_URL, mw, true),
            abi.encode(uint256(0))
        );
    }

    function test_MwSet_CollectW3st_Success() public {
        vm.startPrank(alice);
        uint256 id = CyberEngine(addrs.engine).issueW3st(
            DataTypes.IssueW3stParams(alice, ALICE_ISSUED_1_URL, mw, true),
            abi.encode(uint256(1))
        );

        vm.startPrank(bob);
        vm.expectRevert("INCORRECT_COLLECT_AMOUNT");
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(alice, id, 2, bob, DataTypes.Category.W3ST),
            new bytes(0)
        );

        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(alice, id, 1, bob, DataTypes.Category.W3ST),
            new bytes(0)
        );

        address w3stAddr = CyberEngine(addrs.engine).getW3stAddr(alice);
        assertEq(CyberNFT1155(w3stAddr).balanceOf(bob, id), 1);
        assertEq(CyberNFT1155(w3stAddr).totalSupply(id), 1);

        vm.expectRevert("ALREADY_COLLECTED");
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(alice, id, 1, bob, DataTypes.Category.W3ST),
            new bytes(0)
        );

        vm.expectRevert("COLLECT_LIMIT_EXCEEDED");
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                alice,
                id,
                1,
                alice,
                DataTypes.Category.W3ST
            ),
            new bytes(0)
        );
    }

    function test_MwSet_CollectContent_Success() public {
        vm.startPrank(alice);
        uint256 id = CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, ALICE_ISSUED_1_URL, mw, true),
            abi.encode(uint256(1))
        );

        vm.startPrank(bob);
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                alice,
                id,
                1,
                bob,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );

        address contentAddr = CyberEngine(addrs.engine).getContentAddr(alice);
        assertEq(CyberNFT1155(contentAddr).balanceOf(bob, id), 1);
        assertEq(CyberNFT1155(contentAddr).totalSupply(id), 1);
    }

    function test_MwSet_CollectEssence_Success() public {
        vm.startPrank(alice);
        uint256 id = CyberEngine(addrs.engine).registerEssence(
            DataTypes.RegisterEssenceParams(
                alice,
                "fake essence",
                "FESS",
                ALICE_ISSUED_1_URL,
                mw,
                true
            ),
            abi.encode(uint256(1))
        );

        vm.startPrank(bob);
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                alice,
                id,
                1,
                bob,
                DataTypes.Category.Essence
            ),
            new bytes(0)
        );

        address essenceAddr = CyberEngine(addrs.engine).getEssenceAddr(
            alice,
            id
        );
        assertEq(CyberNFT721(essenceAddr).balanceOf(bob), 1);
        assertEq(CyberNFT721(essenceAddr).totalSupply(), 1);
    }

    function test_MwSet_CollectShare_ExceededLimit() public {
        vm.startPrank(alice);
        uint256 id = CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, ALICE_ISSUED_1_URL, mw, true),
            abi.encode(uint256(1))
        );

        vm.startPrank(bob);
        uint256 shareId = CyberEngine(addrs.engine).share(
            DataTypes.ShareParams(bob, alice, id)
        );

        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                bob,
                shareId,
                1,
                bob,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );

        address contentAddr = CyberEngine(addrs.engine).getContentAddr(alice);
        assertEq(CyberNFT1155(contentAddr).balanceOf(bob, id), 1);
        assertEq(CyberNFT1155(contentAddr).totalSupply(id), 1);

        vm.expectRevert("ALREADY_COLLECTED");
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                bob,
                id,
                1,
                bob,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );

        vm.expectRevert("COLLECT_LIMIT_EXCEEDED");
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                bob,
                id,
                1,
                alice,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
    }
    /* solhint-disable func-name-mixedcase */
}
