// SPDX-License-Identifier: GPL-3.0-or-later
import { ERC721 } from "../../src/dependencies/solmate/ERC721.sol";
import { ERC1155 } from "solmate/src/tokens/ERC1155.sol";

import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";
import { MockMiddleware } from "../utils/MockMiddleware.sol";

import { Soul } from "../../src/core/Soul.sol";
import { Essence } from "../../src/core/Essence.sol";
import { Content } from "../../src/core/Content.sol";
import { W3st } from "../../src/core/W3st.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { MiddlewareManager } from "../../src/core/MiddlewareManager.sol";

import "forge-std/console.sol";

pragma solidity 0.8.14;

contract IntegrationCollectTest is TestIntegrationBase {
    address bob = address(0xB0B);
    address alice = address(0xA11CE);
    address charles = address(0xC);
    address dan = address(0xD);

    address mockMiddleware;

    string constant BOB_ISSUED_1_NAME = "Malzeno Fellwing";
    string constant BOB_ISSUED_1_SYMBOL = "MF";
    string constant BOB_ISSUED_1_URL = "mf.com";

    string constant ALICE_ISSUED_1_NAME = "Something";
    string constant ALICE_ISSUED_1_SYMBOL = "ST";
    string constant ALICE_ISSUED_1_URL = "st.com";

    function setUp() public {
        _setUp();
        mockMiddleware = address(new MockMiddleware());
        vm.prank(protocolOwner);
        MiddlewareManager(addrs.manager).allowMw(address(mockMiddleware), true);
        Soul(addrs.soul).createSoul(bob);
        Soul(addrs.soul).setOrg(bob, true);
        Soul(addrs.soul).createSoul(alice);
        Soul(addrs.soul).createSoul(charles);
    }

    function testRegisterEssence() public {
        uint256 essId = 0;
        vm.expectRevert("ESSENCE_DOES_NOT_EXIST");
        CyberEngine(addrs.engine).getEssenceTransferability(bob, essId);

        vm.startPrank(bob);

        CyberEngine(addrs.engine).registerEssence(
            DataTypes.RegisterEssenceParams(
                bob,
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
            DataTypes.PublishContentParams(
                bob,
                BOB_ISSUED_1_URL,
                address(0),
                true
            ),
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
            DataTypes.IssueW3stParams(bob, BOB_ISSUED_1_URL, address(0), true),
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

    function testCannotIssueW3stNonOrg() public {
        vm.startPrank(alice);

        vm.expectRevert("ONLY_ORG_ACCOUNT");
        CyberEngine(addrs.engine).issueW3st(
            DataTypes.IssueW3stParams(
                alice,
                BOB_ISSUED_1_URL,
                address(0),
                true
            ),
            new bytes(0)
        );
    }

    function testCollectEssence() public {
        uint256 essId = 0;
        vm.prank(bob);

        CyberEngine(addrs.engine).registerEssence(
            DataTypes.RegisterEssenceParams(
                bob,
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
            DataTypes.CollectParams(
                bob,
                essId,
                1,
                alice,
                DataTypes.Category.Essence
            ),
            new bytes(0)
        );
        assertEq(mintedId, 0);
        assertEq(ERC721(BOB_ESS_0_NFT).ownerOf(mintedId), alice);
        vm.prank(alice);
        ERC721(BOB_ESS_0_NFT).transferFrom(alice, bob, mintedId);
        assertEq(ERC721(BOB_ESS_0_NFT).ownerOf(mintedId), bob);
        vm.prank(bob);
        ERC721(BOB_ESS_0_NFT).safeTransferFrom(bob, alice, mintedId);
        assertEq(ERC721(BOB_ESS_0_NFT).ownerOf(mintedId), alice);
        vm.prank(alice);
        ERC721(BOB_ESS_0_NFT).safeTransferFrom(alice, bob, mintedId, "");
        assertEq(ERC721(BOB_ESS_0_NFT).ownerOf(mintedId), bob);
        assertEq(
            ERC721(BOB_ESS_0_NFT).tokenURI(mintedId),
            string(abi.encodePacked(BOB_ISSUED_1_URL, "0"))
        );
        assertTrue(Essence(BOB_ESS_0_NFT).isTransferable());
    }

    function testCannotCollectMoreThanOneEssence() public {
        uint256 essId = 0;
        vm.prank(bob);

        CyberEngine(addrs.engine).registerEssence(
            DataTypes.RegisterEssenceParams(
                bob,
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
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                bob,
                essId,
                2,
                alice,
                DataTypes.Category.Essence
            ),
            new bytes(0)
        );
    }

    function testCollectContent() public {
        uint256 tokenId = 0;
        vm.startPrank(bob);

        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(
                bob,
                BOB_ISSUED_1_URL,
                address(0),
                true
            ),
            new bytes(0)
        );

        address BOB_CONTENT_NFT = CyberEngine(addrs.engine).getContentAddr(bob);

        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                bob,
                tokenId,
                3,
                alice,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
        assertEq(mintedId, 0);
        assertEq(ERC1155(BOB_CONTENT_NFT).balanceOf(alice, mintedId), 3);
        uint256[] memory ids = new uint256[](1);
        ids[0] = mintedId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        vm.prank(alice);
        ERC1155(BOB_CONTENT_NFT).safeBatchTransferFrom(
            alice,
            bob,
            ids,
            amounts,
            new bytes(0)
        );
        assertEq(ERC1155(BOB_CONTENT_NFT).balanceOf(alice, mintedId), 2);
        assertEq(ERC1155(BOB_CONTENT_NFT).balanceOf(bob, mintedId), 1);
        vm.prank(alice);
        ERC1155(BOB_CONTENT_NFT).safeTransferFrom(
            alice,
            bob,
            mintedId,
            2,
            new bytes(0)
        );
        assertEq(ERC1155(BOB_CONTENT_NFT).balanceOf(alice, mintedId), 0);
        assertEq(ERC1155(BOB_CONTENT_NFT).balanceOf(bob, mintedId), 3);
        assertEq(ERC1155(BOB_CONTENT_NFT).uri(mintedId), BOB_ISSUED_1_URL);
        assertTrue(Content(BOB_CONTENT_NFT).isTransferable(mintedId));
    }

    function testCollectW3st() public {
        uint256 tokenId = 0;
        vm.startPrank(bob);

        CyberEngine(addrs.engine).issueW3st(
            DataTypes.IssueW3stParams(bob, BOB_ISSUED_1_URL, address(0), true),
            new bytes(0)
        );

        address BOB_W3ST_NFT = CyberEngine(addrs.engine).getW3stAddr(bob);

        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                bob,
                tokenId,
                3,
                alice,
                DataTypes.Category.W3ST
            ),
            new bytes(0)
        );
        assertEq(mintedId, 0);
        assertEq(ERC1155(BOB_W3ST_NFT).balanceOf(alice, mintedId), 3);

        uint256[] memory ids = new uint256[](1);
        ids[0] = mintedId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        vm.prank(alice);
        ERC1155(BOB_W3ST_NFT).safeBatchTransferFrom(
            alice,
            bob,
            ids,
            amounts,
            new bytes(0)
        );
        assertEq(ERC1155(BOB_W3ST_NFT).balanceOf(alice, mintedId), 2);
        assertEq(ERC1155(BOB_W3ST_NFT).balanceOf(bob, mintedId), 1);
        vm.prank(alice);
        ERC1155(BOB_W3ST_NFT).safeTransferFrom(
            alice,
            bob,
            mintedId,
            2,
            new bytes(0)
        );
        assertEq(ERC1155(BOB_W3ST_NFT).balanceOf(alice, mintedId), 0);
        assertEq(ERC1155(BOB_W3ST_NFT).balanceOf(bob, mintedId), 3);
        assertEq(ERC1155(BOB_W3ST_NFT).uri(mintedId), BOB_ISSUED_1_URL);
    }

    function testComment() public {
        vm.startPrank(bob);

        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(
                bob,
                BOB_ISSUED_1_URL,
                address(0),
                true
            ),
            new bytes(0)
        );

        uint256 idCommented = 0;

        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).comment(
            DataTypes.CommentParams(
                alice,
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
        vm.startPrank(bob);

        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(
                bob,
                BOB_ISSUED_1_URL,
                address(0),
                true
            ),
            new bytes(0)
        );

        uint256 idCommented = 0;

        // alice comment on bob's content
        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).comment(
            DataTypes.CommentParams(
                alice,
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
                charles,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
        assertEq(ERC1155(ALICE_CONTENT_NFT).balanceOf(charles, mintedId), 1000);
    }

    function testShare() public {
        vm.startPrank(bob);

        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(
                bob,
                BOB_ISSUED_1_URL,
                address(0),
                true
            ),
            new bytes(0)
        );

        uint256 idShared = 0;

        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).share(
            DataTypes.ShareParams(alice, bob, idShared)
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
        vm.startPrank(bob);

        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(
                bob,
                BOB_ISSUED_1_URL,
                address(0),
                true
            ),
            new bytes(0)
        );

        uint256 idShared = 0;

        // alice share bob's content
        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).share(
            DataTypes.ShareParams(alice, bob, idShared)
        );

        // charles share alice's share
        vm.prank(charles);
        uint256 mintedIdCharles = CyberEngine(addrs.engine).share(
            DataTypes.ShareParams(charles, alice, mintedId)
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
                alice,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
        assertEq(ERC1155(BOB_CONTENT_NFT).balanceOf(alice, mintedIdCharles), 5);
    }

    function testCollectEssenceWithMw() public {
        bytes memory mockData = abi.encode("tmp");
        uint256 essId = 0;
        vm.prank(bob);

        CyberEngine(addrs.engine).registerEssence(
            DataTypes.RegisterEssenceParams(
                bob,
                BOB_ISSUED_1_NAME,
                BOB_ISSUED_1_SYMBOL,
                BOB_ISSUED_1_URL,
                mockMiddleware,
                false
            ),
            mockData
        );

        address BOB_ESS_0_NFT = CyberEngine(addrs.engine).getEssenceAddr(
            bob,
            essId
        );

        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                bob,
                essId,
                1,
                alice,
                DataTypes.Category.Essence
            ),
            new bytes(0)
        );
        assertEq(mintedId, 0);
        assertEq(ERC721(BOB_ESS_0_NFT).ownerOf(mintedId), alice);
        assertEq(
            MockMiddleware(mockMiddleware).getMwData(
                bob,
                DataTypes.Category.Essence,
                essId
            ),
            mockData
        );

        vm.prank(alice);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        ERC721(BOB_ESS_0_NFT).transferFrom(alice, bob, mintedId);
        vm.prank(alice);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        ERC721(BOB_ESS_0_NFT).safeTransferFrom(alice, bob, mintedId);
        vm.prank(alice);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        ERC721(BOB_ESS_0_NFT).safeTransferFrom(alice, bob, mintedId, "");
        assertFalse(Essence(BOB_ESS_0_NFT).isTransferable());
    }

    function testCollectContentWithMw() public {
        bytes memory mockData = abi.encode("tmp");
        vm.prank(bob);

        uint256 tokenId = CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(
                bob,
                BOB_ISSUED_1_URL,
                mockMiddleware,
                false
            ),
            mockData
        );

        address BOB_CONTENT_NFT = CyberEngine(addrs.engine).getContentAddr(bob);

        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                bob,
                tokenId,
                1,
                alice,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
        assertEq(mintedId, 0);
        assertEq(ERC1155(BOB_CONTENT_NFT).balanceOf(alice, tokenId), 1);
        assertEq(
            MockMiddleware(mockMiddleware).getMwData(
                bob,
                DataTypes.Category.Content,
                tokenId
            ),
            mockData
        );
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        vm.prank(alice);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        ERC1155(BOB_CONTENT_NFT).safeBatchTransferFrom(
            alice,
            bob,
            ids,
            amounts,
            new bytes(0)
        );
        vm.prank(alice);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        ERC1155(BOB_CONTENT_NFT).safeTransferFrom(
            alice,
            bob,
            tokenId,
            1,
            new bytes(0)
        );
        assertFalse(Content(BOB_CONTENT_NFT).isTransferable(mintedId));
    }

    function testCollectCommentWithMw() public {
        bytes memory mockData = abi.encode("tmp");
        vm.startPrank(bob);

        CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(
                bob,
                BOB_ISSUED_1_URL,
                address(0),
                true
            ),
            new bytes(0)
        );

        uint256 idCommented = 0;

        // alice comment on bob's content
        vm.prank(alice);
        uint256 tokenId = CyberEngine(addrs.engine).comment(
            DataTypes.CommentParams(
                alice,
                ALICE_ISSUED_1_URL,
                mockMiddleware,
                true,
                bob,
                idCommented
            ),
            mockData
        );

        // collect on alice's comment will lead to collect on the comment itself (instead of origial content).
        address ALICE_CONTENT_NFT = CyberEngine(addrs.engine).getContentAddr(
            alice
        );

        vm.prank(charles);
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                alice,
                tokenId,
                1000,
                charles,
                DataTypes.Category.Content
            ),
            new bytes(0)
        );
        assertEq(ERC1155(ALICE_CONTENT_NFT).balanceOf(charles, tokenId), 1000);
        assertEq(
            MockMiddleware(mockMiddleware).getMwData(
                alice,
                DataTypes.Category.Content,
                tokenId
            ),
            mockData
        );
    }

    function testCollectW3stWithMw() public {
        bytes memory mockData = abi.encode("tmp");
        vm.startPrank(bob);

        uint256 tokenId = CyberEngine(addrs.engine).issueW3st(
            DataTypes.IssueW3stParams(
                bob,
                BOB_ISSUED_1_URL,
                mockMiddleware,
                false
            ),
            mockData
        );

        address BOB_W3ST_NFT = CyberEngine(addrs.engine).getW3stAddr(bob);

        vm.prank(alice);
        uint256 mintedId = CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(
                bob,
                tokenId,
                3,
                alice,
                DataTypes.Category.W3ST
            ),
            new bytes(0)
        );
        assertEq(mintedId, 0);
        assertEq(ERC1155(BOB_W3ST_NFT).balanceOf(alice, mintedId), 3);
        assertEq(
            MockMiddleware(mockMiddleware).getMwData(
                bob,
                DataTypes.Category.W3ST,
                tokenId
            ),
            mockData
        );

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        vm.prank(alice);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        ERC1155(BOB_W3ST_NFT).safeBatchTransferFrom(
            alice,
            bob,
            ids,
            amounts,
            new bytes(0)
        );
        vm.prank(alice);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        ERC1155(BOB_W3ST_NFT).safeTransferFrom(
            alice,
            bob,
            tokenId,
            1,
            new bytes(0)
        );
    }

    function testSetEssenceData() public {
        bytes memory mockData = abi.encode("tmp");
        string memory newTokenUri = "newUri";
        vm.prank(bob);
        uint256 essId = CyberEngine(addrs.engine).registerEssence(
            DataTypes.RegisterEssenceParams(
                bob,
                BOB_ISSUED_1_NAME,
                BOB_ISSUED_1_SYMBOL,
                BOB_ISSUED_1_URL,
                address(0),
                true
            ),
            new bytes(0)
        );

        vm.prank(bob);
        CyberEngine(addrs.engine).setEssenceData(
            bob,
            essId,
            newTokenUri,
            mockMiddleware,
            mockData
        );
        assertEq(
            MockMiddleware(mockMiddleware).getMwData(
                bob,
                DataTypes.Category.Essence,
                essId
            ),
            mockData
        );
        assertEq(
            CyberEngine(addrs.engine).getEssenceTokenURI(bob, essId),
            newTokenUri
        );
        assertEq(
            CyberEngine(addrs.engine).getEssenceMw(bob, essId),
            mockMiddleware
        );
    }

    function testSetContentData() public {
        bytes memory mockData = abi.encode("tmp");
        string memory newTokenUri = "newUri";
        vm.prank(bob);

        uint256 tokenId = CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(
                bob,
                BOB_ISSUED_1_URL,
                address(0),
                true
            ),
            new bytes(0)
        );

        CyberEngine(addrs.engine).getContentAddr(bob);

        vm.prank(bob);
        CyberEngine(addrs.engine).setContentData(
            bob,
            tokenId,
            newTokenUri,
            mockMiddleware,
            mockData
        );
        assertEq(
            MockMiddleware(mockMiddleware).getMwData(
                bob,
                DataTypes.Category.Content,
                tokenId
            ),
            mockData
        );
        assertEq(
            CyberEngine(addrs.engine).getContentTokenURI(bob, tokenId),
            newTokenUri
        );
        assertEq(
            CyberEngine(addrs.engine).getContentMw(bob, tokenId),
            mockMiddleware
        );
    }

    function testSetW3stData() public {
        bytes memory mockData = abi.encode("tmp");
        string memory newTokenUri = "newUri";
        vm.startPrank(bob);

        uint256 tokenId = CyberEngine(addrs.engine).issueW3st(
            DataTypes.IssueW3stParams(bob, BOB_ISSUED_1_URL, address(0), true),
            new bytes(0)
        );

        vm.startPrank(bob);
        CyberEngine(addrs.engine).setW3stData(
            bob,
            tokenId,
            newTokenUri,
            mockMiddleware,
            mockData
        );

        assertEq(
            MockMiddleware(mockMiddleware).getMwData(
                bob,
                DataTypes.Category.W3ST,
                tokenId
            ),
            mockData
        );
        assertEq(
            CyberEngine(addrs.engine).getW3stTokenURI(bob, tokenId),
            newTokenUri
        );
        assertEq(
            CyberEngine(addrs.engine).getW3stMw(bob, tokenId),
            mockMiddleware
        );
    }

    function testNonSoulOwnerSetOperatorApproval() public {
        vm.prank(dan);
        vm.expectRevert("ONLY_SOUL_OWNER");
        CyberEngine(addrs.engine).setOperatorApproval(alice, true);
    }

    function testOperatorPublishContent() public {
        bytes memory mockData = abi.encode("tmp");
        string memory newTokenUri = "newUri";
        vm.startPrank(bob);
        CyberEngine(addrs.engine).setOperatorApproval(alice, true);

        vm.startPrank(alice);
        uint256 tokenId = CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(
                bob,
                BOB_ISSUED_1_URL,
                address(0),
                true
            ),
            new bytes(0)
        );

        vm.startPrank(alice);
        CyberEngine(addrs.engine).setContentData(
            bob,
            tokenId,
            newTokenUri,
            mockMiddleware,
            mockData
        );
        assertEq(
            MockMiddleware(mockMiddleware).getMwData(
                bob,
                DataTypes.Category.Content,
                tokenId
            ),
            mockData
        );
        assertEq(
            CyberEngine(addrs.engine).getContentTokenURI(bob, tokenId),
            newTokenUri
        );
        assertEq(
            CyberEngine(addrs.engine).getContentMw(bob, tokenId),
            mockMiddleware
        );
        assertEq(
            CyberEngine(addrs.engine).getOperatorApproval(bob, alice),
            true
        );
    }

    function testMiddlewareManagerDisallowMw() public {
        vm.prank(protocolOwner);
        MiddlewareManager(addrs.manager).allowMw(mockMiddleware, false);
        assertFalse(
            MiddlewareManager(addrs.manager).isMwAllowed(mockMiddleware)
        );
    }
}
