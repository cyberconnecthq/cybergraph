// SPDX-License-Identifier: GPL-3.0-or-later
import { ERC721 } from "../../src/dependencies/solmate/ERC721.sol";
import { ERC1155 } from "solmate/src/tokens/ERC1155.sol";

import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";
import { Soul } from "../../src/core/Soul.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";

import "forge-std/console.sol";

pragma solidity 0.8.14;

contract IntegrationCollectTest is TestIntegrationBase {
    address bob = address(0xB0B);
    address alice = address(0xA11CE);
    address charles = address(0xC);

    string constant BOB_ISSUED_1_NAME = "Malzeno Fellwing";
    string constant BOB_ISSUED_1_SYMBOL = "MF";
    string constant BOB_ISSUED_1_URL = "mf.com";

    string constant ALICE_ISSUED_1_NAME = "Something";
    string constant ALICE_ISSUED_1_SYMBOL = "ST";
    string constant ALICE_ISSUED_1_URL = "st.com";

    function setUp() public {
        _setUp();
        Soul(addrs.soul).mint(bob);
        Soul(addrs.soul).mint(alice);
        Soul(addrs.soul).mint(charles);
    }

    function testRegisterEssence() public {
        uint256 essId = 0;
        vm.expectRevert("ESSENCE_DOES_NOT_EXIST");
        CyberEngine(addrs.engine).getEssenceTransferability(bob, essId);

        vm.startPrank(bob);

        CyberEngine(addrs.engine).registerEssence(
            DataTypes.RegisterEssenceParams(
                BOB_ISSUED_1_NAME,
                BOB_ISSUED_1_SYMBOL,
                BOB_ISSUED_1_URL,
                address(0),
                true
            ),
            new bytes(0)
        );

        assertEq(CyberEngine(addrs.engine).getEssenceCount(bob), 1);
        assertEq(
            CyberEngine(addrs.engine).getEssenceTokenURI(bob, essId),
            BOB_ISSUED_1_URL
        );
        assertEq(
            CyberEngine(addrs.engine).getEssenceTransferability(bob, essId),
            true
        );
    }

    function testPublishContent() public {
        uint256 tokenId = 0;

        vm.expectRevert("CONTENT_DOES_NOT_EXIST");
        CyberEngine(addrs.engine).getContentTokenURI(bob, tokenId);

        vm.startPrank(bob);

        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(BOB_ISSUED_1_URL, address(0), true),
            new bytes(0)
        );

        assertEq(CyberEngine(addrs.engine).getContentCount(bob), 1);
        assertEq(
            CyberEngine(addrs.engine).getContentTokenURI(bob, tokenId),
            BOB_ISSUED_1_URL
        );
        assertEq(
            CyberEngine(addrs.engine).getContentTransferability(bob, tokenId),
            true
        );
    }

    function testIssueW3st() public {
        uint256 tokenId = 0;

        vm.expectRevert("W3ST_DOES_NOT_EXIST");
        CyberEngine(addrs.engine).getW3stTokenURI(bob, tokenId);

        vm.startPrank(bob);

        CyberEngine(addrs.engine).issueW3st(
            DataTypes.IssueW3stParams(BOB_ISSUED_1_URL, address(0), true),
            new bytes(0)
        );

        assertEq(CyberEngine(addrs.engine).getW3stCount(bob), 1);
        assertEq(
            CyberEngine(addrs.engine).getW3stTokenURI(bob, tokenId),
            BOB_ISSUED_1_URL
        );
        assertEq(
            CyberEngine(addrs.engine).getW3stTransferability(bob, tokenId),
            true
        );
    }

    function testCollectEssence() public {
        uint256 essId = 0;
        vm.prank(bob);

        CyberEngine(addrs.engine).registerEssence(
            DataTypes.RegisterEssenceParams(
                BOB_ISSUED_1_NAME,
                BOB_ISSUED_1_SYMBOL,
                BOB_ISSUED_1_URL,
                address(0),
                true
            ),
            new bytes(0)
        );

        address BOB_ESS_0_NFT = CyberEngine(addrs.engine).getEssenceAddr(
            bob,
            essId
        );

        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(bob, essId, 1, DataTypes.Category.Essence),
            new bytes(0)
        );
        assertEq(mintedId, 0);
        assertEq(ERC721(BOB_ESS_0_NFT).ownerOf(mintedId), alice);
    }

    function testCannotCollectMoreThanOneEssence() public {
        uint256 essId = 0;
        vm.prank(bob);

        CyberEngine(addrs.engine).registerEssence(
            DataTypes.RegisterEssenceParams(
                BOB_ISSUED_1_NAME,
                BOB_ISSUED_1_SYMBOL,
                BOB_ISSUED_1_URL,
                address(0),
                true
            ),
            new bytes(0)
        );

        vm.prank(alice);
        vm.expectRevert("INCORRECT_COLLECT_AMOUNT");
        uint256 mintedId = CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(bob, essId, 2, DataTypes.Category.Essence),
            new bytes(0)
        );
    }

    function testCollectContent() public {
        uint256 tokenId = 0;
        vm.startPrank(bob);

        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(BOB_ISSUED_1_URL, address(0), true),
            new bytes(0)
        );

        address BOB_CONTENT_NFT = CyberEngine(addrs.engine).getContentAddr(bob);

        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                bob,
                tokenId,
                3,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
        assertEq(mintedId, 0);
        assertEq(ERC1155(BOB_CONTENT_NFT).balanceOf(alice, mintedId), 3);
    }

    function testCollectW3st() public {
        uint256 tokenId = 0;
        vm.startPrank(bob);

        CyberEngine(addrs.engine).issueW3st(
            DataTypes.IssueW3stParams(BOB_ISSUED_1_URL, address(0), true),
            new bytes(0)
        );

        address BOB_W3ST_NFT = CyberEngine(addrs.engine).getW3stAddr(bob);

        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(bob, tokenId, 3, DataTypes.Category.W3ST),
            new bytes(0)
        );
        assertEq(mintedId, 0);
        assertEq(ERC1155(BOB_W3ST_NFT).balanceOf(alice, mintedId), 3);
    }

    function testComment() public {
        uint256 tokenId = 0;
        vm.startPrank(bob);

        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(BOB_ISSUED_1_URL, address(0), true),
            new bytes(0)
        );

        uint256 idCommented = 0;

        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).comment(
            DataTypes.CommentParams(
                ALICE_ISSUED_1_URL,
                address(0),
                true,
                bob,
                idCommented
            ),
            new bytes(0)
        );

        assertEq(
            CyberEngine(addrs.engine).getContentAddr(alice) == address(0),
            false
        );
        assertEq(CyberEngine(addrs.engine).getContentCount(alice), 1);
        assertEq(
            CyberEngine(addrs.engine).getContentTokenURI(alice, mintedId),
            ALICE_ISSUED_1_URL
        );
        assertEq(
            CyberEngine(addrs.engine).getContentTransferability(
                alice,
                mintedId
            ),
            true
        );

        (address srcAcc, uint256 srcId) = CyberEngine(addrs.engine)
            .getContentSrcInfo(alice, mintedId);
        assertEq(srcAcc, bob);
        assertEq(srcId, idCommented);
    }

    function testCollectComment() public {
        uint256 tokenId = 0;
        vm.startPrank(bob);

        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(BOB_ISSUED_1_URL, address(0), true),
            new bytes(0)
        );

        uint256 idCommented = 0;

        // alice comment on bob's content
        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).comment(
            DataTypes.CommentParams(
                ALICE_ISSUED_1_URL,
                address(0),
                true,
                bob,
                idCommented
            ),
            new bytes(0)
        );

        // collect on alice's comment will lead to collect on the comment itself (instead of origial content).
        address ALICE_CONTENT_NFT = CyberEngine(addrs.engine).getContentAddr(
            alice
        );

        vm.prank(charles);
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                alice,
                mintedId,
                1000,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
        assertEq(ERC1155(ALICE_CONTENT_NFT).balanceOf(charles, mintedId), 1000);
    }

    function testShare() public {
        uint256 tokenId = 0;
        vm.startPrank(bob);

        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(BOB_ISSUED_1_URL, address(0), true),
            new bytes(0)
        );

        uint256 idShared = 0;

        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).share(
            DataTypes.ShareParams(bob, idShared)
        );

        assertEq(
            CyberEngine(addrs.engine).getContentAddr(alice) == address(0),
            false
        );
        assertEq(CyberEngine(addrs.engine).getContentCount(alice), 1);

        (address srcAcc, uint256 srcId) = CyberEngine(addrs.engine)
            .getContentSrcInfo(alice, mintedId);
        assertEq(srcAcc, bob);
        assertEq(srcId, idShared);

        // shared tokenURI will point to the src one
        assertEq(
            CyberEngine(addrs.engine).getContentTokenURI(alice, mintedId),
            BOB_ISSUED_1_URL
        );
    }

    function testCollectShareShare() public {
        uint256 tokenId = 0;
        vm.startPrank(bob);

        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(BOB_ISSUED_1_URL, address(0), true),
            new bytes(0)
        );

        uint256 idShared = 0;

        // alice share bob's content
        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).share(
            DataTypes.ShareParams(bob, idShared)
        );

        // charles share alice's share
        vm.prank(charles);
        uint256 mintedIdCharles = CyberEngine(addrs.engine).share(
            DataTypes.ShareParams(alice, mintedId)
        );

        // src info will point to alice's original content
        (address srcAcc, uint256 srcId) = CyberEngine(addrs.engine)
            .getContentSrcInfo(charles, mintedIdCharles);
        assertEq(srcAcc, bob);
        assertEq(srcId, idShared);
        assertEq(
            CyberEngine(addrs.engine).getContentTokenURI(
                charles,
                mintedIdCharles
            ),
            BOB_ISSUED_1_URL
        );

        // collect on charles's share will lead to collect on bob's content
        address BOB_CONTENT_NFT = CyberEngine(addrs.engine).getContentAddr(bob);

        vm.prank(alice);
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                charles,
                mintedIdCharles,
                5,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
        assertEq(ERC1155(BOB_CONTENT_NFT).balanceOf(alice, mintedIdCharles), 5);
    }
}
