// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Soul } from "../src/core/Soul.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";

import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "forge-std/console.sol";
import "forge-std/Test.sol";

contract SoulTest is Test {
    address public soulOwner = address(0x1);
    address public alice = address(0x2);
    address public bob = address(0x3);
    address public soulProxy;

    function setUp() public {
        soulProxy = address(new Soul(soulOwner, "soul", "SOUL"));
    }

    /* solhint-disable func-name-mixedcase */
    function testInitialize() public {
        assertEq(Soul(soulProxy).owner(), soulOwner);
        assertEq(Soul(soulProxy).name(), "soul");
        assertEq(Soul(soulProxy).symbol(), "SOUL");
    }

    function testCreateNonOrgSoul() public {
        vm.prank(soulOwner);
        Soul(soulProxy).createSoul(alice);
        assertEq(
            Soul(soulProxy).ownerOf(Soul(soulProxy).getTokenId(alice)),
            alice
        );
        assertFalse(Soul(soulProxy).isOrgAccount(alice));
    }

    function testPromoteToOrg() public {
        vm.prank(soulOwner);
        Soul(soulProxy).createSoul(alice);
        assertEq(
            Soul(soulProxy).ownerOf(Soul(soulProxy).getTokenId(alice)),
            alice
        );
        assertFalse(Soul(soulProxy).isOrgAccount(alice));

        vm.prank(soulOwner);
        Soul(soulProxy).setOrg(alice, true);
        assertTrue(Soul(soulProxy).isOrgAccount(alice));
    }

    function testOrgDegrade() public {
        vm.prank(soulOwner);
        Soul(soulProxy).createSoul(alice);
        vm.prank(soulOwner);
        Soul(soulProxy).setOrg(alice, true);
        assertEq(
            Soul(soulProxy).ownerOf(Soul(soulProxy).getTokenId(alice)),
            alice
        );
        assertTrue(Soul(soulProxy).isOrgAccount(alice));

        vm.prank(soulOwner);
        Soul(soulProxy).setOrg(alice, false);
        assertFalse(Soul(soulProxy).isOrgAccount(alice));
    }

    function testSoulCannotTransfer() public {
        vm.prank(soulOwner);
        Soul(soulProxy).createSoul(alice);

        uint256 id = Soul(soulProxy).getTokenId(alice);
        vm.prank(alice);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        Soul(soulProxy).transferFrom(alice, bob, id);

        vm.prank(alice);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        Soul(soulProxy).safeTransferFrom(alice, bob, id);

        vm.prank(alice);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        Soul(soulProxy).safeTransferFrom(alice, bob, id, "");
    }

    function testGetTokenURI() public {
        vm.prank(soulOwner);
        Soul(soulProxy).createSoul(alice);

        assertEq(
            Soul(soulProxy).tokenURI(Soul(soulProxy).getTokenId(alice)),
            "96410720129710237375451070825415435584404743201776233794242755335442674601826"
        );

        vm.expectRevert("NOT_MINTED");
        assertEq(Soul(soulProxy).tokenURI(0), "");
    }

    function testOnlyMinterCanMint() public {
        vm.prank(alice);
        vm.expectRevert("ONLY_MINTER");
        Soul(soulProxy).createSoul(alice);

        vm.prank(soulOwner);
        Soul(soulProxy).setMinter(alice, true);

        vm.prank(alice);
        Soul(soulProxy).createSoul(alice);
        assertEq(
            Soul(soulProxy).ownerOf(Soul(soulProxy).getTokenId(alice)),
            alice
        );
    }

    function test_SoulMinted_SetMetadata_ReadSuccess() public {
        vm.prank(soulOwner);
        uint256 tokenId = Soul(soulProxy).createSoul(alice);

        string memory avatarKey = "avatar";
        string
            memory avatarValue = "ipfs://Qmb5YRL6hjutLUF2dw5V5WGjQCip4e1WpRo8w3iFss4cWB";
        DataTypes.MetadataPair[]
            memory metadatas = new DataTypes.MetadataPair[](1);
        metadatas[0] = DataTypes.MetadataPair(avatarKey, avatarValue);
        vm.startPrank(alice);
        Soul(soulProxy).batchSetMetadatas(tokenId, metadatas);
        assertEq(avatarValue, Soul(soulProxy).getMetadata(tokenId, avatarKey));
        metadatas[0] = DataTypes.MetadataPair(avatarKey, unicode"中文");
        Soul(soulProxy).batchSetMetadatas(tokenId, metadatas);
        assertEq(
            unicode"中文",
            Soul(soulProxy).getMetadata(tokenId, avatarKey)
        );
    }

    function test_SoulMinted_ClearMetadata_ReadSuccess() public {
        vm.prank(soulOwner);
        uint256 tokenId = Soul(soulProxy).createSoul(alice);

        DataTypes.MetadataPair[]
            memory metadatas = new DataTypes.MetadataPair[](2);
        metadatas[0] = DataTypes.MetadataPair("1", "1");
        metadatas[1] = DataTypes.MetadataPair("2", "2");
        vm.startPrank(alice);
        Soul(soulProxy).batchSetMetadatas(tokenId, metadatas);
        assertEq(Soul(soulProxy).getMetadata(tokenId, "1"), "1");
        assertEq(Soul(soulProxy).getMetadata(tokenId, "2"), "2");
        Soul(soulProxy).clearMetadatas(tokenId);
        assertEq(Soul(soulProxy).getMetadata(tokenId, "1"), "");
        assertEq(Soul(soulProxy).getMetadata(tokenId, "2"), "");
    }

    function test_SoulNotMinted_SetMetadata_Revert() public {
        uint256 tokenId = 0;
        string memory avatarKey = "avatar";
        string
            memory avatarValue = "ipfs://Qmb5YRL6hjutLUF2dw5V5WGjQCip4e1WpRo8w3iFss4cWB";
        DataTypes.MetadataPair[]
            memory metadatas = new DataTypes.MetadataPair[](1);
        metadatas[0] = DataTypes.MetadataPair(avatarKey, avatarValue);
        vm.prank(soulOwner);
        vm.expectRevert("METADATA_UNAUTHORISED");
        Soul(soulProxy).batchSetMetadatas(tokenId, metadatas);
    }

    function test_SoulMinted_ClearMetadataByOthers_RevertUnAuth() public {
        vm.prank(soulOwner);
        uint256 tokenId = Soul(soulProxy).createSoul(alice);

        DataTypes.MetadataPair[]
            memory metadatas = new DataTypes.MetadataPair[](2);
        metadatas[0] = DataTypes.MetadataPair("1", "1");
        metadatas[1] = DataTypes.MetadataPair("2", "2");
        vm.startPrank(alice);
        Soul(soulProxy).batchSetMetadatas(tokenId, metadatas);
        assertEq(Soul(soulProxy).getMetadata(tokenId, "1"), "1");
        assertEq(Soul(soulProxy).getMetadata(tokenId, "2"), "2");
        vm.stopPrank();
        vm.startPrank(bob);
        vm.expectRevert("METADATA_UNAUTHORISED");
        Soul(soulProxy).clearMetadatas(tokenId);
        assertEq(Soul(soulProxy).getMetadata(tokenId, "1"), "1");
        assertEq(Soul(soulProxy).getMetadata(tokenId, "2"), "2");
    }

    function test_SoulMinted_SetGatedMetadata_ReadSuccess() public {
        vm.startPrank(soulOwner);
        uint256 tokenId = Soul(soulProxy).createSoul(alice);

        string memory avatarKey = "avatar";
        string
            memory avatarValue = "ipfs://Qmb5YRL6hjutLUF2dw5V5WGjQCip4e1WpRo8w3iFss4cWB";
        DataTypes.MetadataPair[]
            memory metadatas = new DataTypes.MetadataPair[](1);
        metadatas[0] = DataTypes.MetadataPair(avatarKey, avatarValue);
        Soul(soulProxy).batchSetGatedMetadatas(tokenId, metadatas);
        assertEq(
            avatarValue,
            Soul(soulProxy).getGatedMetadata(tokenId, avatarKey)
        );
        metadatas[0] = DataTypes.MetadataPair(avatarKey, unicode"中文");
        Soul(soulProxy).batchSetGatedMetadatas(tokenId, metadatas);
        assertEq(
            unicode"中文",
            Soul(soulProxy).getGatedMetadata(tokenId, avatarKey)
        );
    }

    function test_GatedMetadataSet_ClearGatedMetadata_ReadSuccess() public {
        vm.startPrank(soulOwner);
        uint256 tokenId = Soul(soulProxy).createSoul(alice);

        DataTypes.MetadataPair[]
            memory metadatas = new DataTypes.MetadataPair[](2);
        metadatas[0] = DataTypes.MetadataPair("1", "1");
        metadatas[1] = DataTypes.MetadataPair("2", "2");
        Soul(soulProxy).batchSetGatedMetadatas(tokenId, metadatas);
        assertEq(Soul(soulProxy).getGatedMetadata(tokenId, "1"), "1");
        assertEq(Soul(soulProxy).getGatedMetadata(tokenId, "2"), "2");
        Soul(soulProxy).clearGatedMetadatas(tokenId);
        assertEq(Soul(soulProxy).getGatedMetadata(tokenId, "1"), "");
        assertEq(Soul(soulProxy).getGatedMetadata(tokenId, "2"), "");
    }

    function test_GatedMetadataSet_ClearGatedMetadataByOthers_RevertUnAuth()
        public
    {
        vm.startPrank(soulOwner);
        uint256 tokenId = Soul(soulProxy).createSoul(alice);

        DataTypes.MetadataPair[]
            memory metadatas = new DataTypes.MetadataPair[](2);
        metadatas[0] = DataTypes.MetadataPair("1", "1");
        metadatas[1] = DataTypes.MetadataPair("2", "2");
        Soul(soulProxy).batchSetGatedMetadatas(tokenId, metadatas);
        assertEq(Soul(soulProxy).getGatedMetadata(tokenId, "1"), "1");
        assertEq(Soul(soulProxy).getGatedMetadata(tokenId, "2"), "2");
        vm.stopPrank();
        vm.startPrank(bob);
        vm.expectRevert("GATED_METADATA_UNAUTHORISED");
        Soul(soulProxy).clearGatedMetadatas(tokenId);
        assertEq(Soul(soulProxy).getGatedMetadata(tokenId, "1"), "1");
        assertEq(Soul(soulProxy).getGatedMetadata(tokenId, "2"), "2");
    }
    /* solhint-disable func-name-mixedcase */
}
