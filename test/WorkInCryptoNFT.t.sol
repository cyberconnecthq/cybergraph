// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/console.sol";
import "forge-std/Test.sol";

import { WorkInCryptoNFT } from "../src/periphery/WorkInCryptoNFT.sol";
import { LibString } from "../src/libraries/LibString.sol";
import { TestLib712 } from "./utils/TestLib712.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";

contract WorkInCryptoNFTTest is Test {
    uint256 public ownerSk = 123;
    uint256 public signerSk = 456;
    uint256 public signer2Sk = 789;
    address public owner = vm.addr(ownerSk);
    address public signer = vm.addr(signerSk);
    address public signer2 = vm.addr(signer2Sk);
    address public alice = address(0x2);
    address public bob = address(0x3);

    WorkInCryptoNFT nft;

    bytes32 internal constant _MINTER_ROLE = keccak256(bytes("MINTER_ROLE"));

    bytes32 internal constant _MINT_TYPEHASH =
        keccak256("mint(address to,uint256 nonce,uint256 deadline)");

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event BaseTokenURISet(string uri);

    function setUp() public {
        nft = new WorkInCryptoNFT(
            "WorkInCryptoNFT",
            "WICNFT",
            "https://uri.com/",
            owner,
            signer
        );
    }

    /*//////////////////////////////////////////////////////////////
                                1
    //////////////////////////////////////////////////////////////*/

    function testMint() public {
        vm.prank(owner);
        nft.mint(alice);
        assertEq(nft.ownerOf(1), alice);
    }

    function testMintNotMinter() public {
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                LibString.toHexString(alice),
                " is missing role ",
                LibString.toHexString(uint256(_MINTER_ROLE), 32)
            )
        );
        vm.prank(alice);
        nft.mint(alice);
    }

    /*//////////////////////////////////////////////////////////////
                            MINT WITH SIG
    //////////////////////////////////////////////////////////////*/

    function testMintWithSig() public {
        uint256 nonce = nft.getNonce(alice);
        DataTypes.EIP712Signature memory sig = _generateSig(
            signerSk,
            alice,
            nonce,
            block.timestamp
        );
        nft.mintWithSig(alice, sig);
        assertEq(nft.ownerOf(1), alice);
    }

    function testMintWithSigNotSigner() public {
        uint256 nonce = nft.getNonce(alice);
        DataTypes.EIP712Signature memory sig = _generateSig(
            ownerSk,
            alice,
            nonce,
            block.timestamp
        );
        vm.expectRevert("INVALID_SIGNATURE");
        nft.mintWithSig(alice, sig);
    }

    function testMintWithSigErrorAccount() public {
        uint256 nonce = nft.getNonce(alice);
        DataTypes.EIP712Signature memory sig = _generateSig(
            signerSk,
            bob,
            nonce,
            block.timestamp
        );
        vm.expectRevert("INVALID_SIGNATURE");
        nft.mintWithSig(alice, sig);
    }

    function testMintWithSigErrorNonce() public {
        uint256 nonce = nft.getNonce(alice);
        DataTypes.EIP712Signature memory sig = _generateSig(
            signerSk,
            alice,
            nonce + 1,
            block.timestamp
        );
        vm.expectRevert("INVALID_SIGNATURE");
        nft.mintWithSig(alice, sig);
    }

    function testMintWithSigWithExpiredDeadline() public {
        uint256 nonce = nft.getNonce(alice);
        DataTypes.EIP712Signature memory sig = _generateSig(
            signerSk,
            alice,
            nonce,
            block.timestamp - 1
        );
        vm.expectRevert("DEADLINE_EXCEEDED");
        nft.mintWithSig(alice, sig);
    }

    function _generateSig(
        uint256 _signerSk,
        address to,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (DataTypes.EIP712Signature memory sig) {
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(nft),
            keccak256(abi.encode(_MINT_TYPEHASH, to, nonce, deadline)),
            "WorkInCryptoNFT",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signerSk, digest);
        return DataTypes.EIP712Signature(v, r, s, deadline);
    }

    /*//////////////////////////////////////////////////////////////
                            SET SIGNER
    //////////////////////////////////////////////////////////////*/

    function testSetSigner() public {
        vm.prank(owner);
        nft.setSigner(signer2);
        assertEq(nft.getSinger(), signer2);
    }

    function testSetSignerNotOwner() public {
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                LibString.toHexString(alice),
                " is missing role ",
                LibString.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.prank(alice);
        nft.setSigner(signer2);
    }

    function testMintWithSigAfterChangeSigner() public {
        vm.prank(owner);
        nft.setSigner(signer2);
        assertEq(nft.getSinger(), signer2);

        uint256 nonce = nft.getNonce(alice);
        DataTypes.EIP712Signature memory sig = _generateSig(
            signer2Sk,
            alice,
            nonce,
            block.timestamp
        );
        nft.mintWithSig(alice, sig);
        assertEq(nft.ownerOf(1), alice);
    }

    /*//////////////////////////////////////////////////////////////
                            PAUSE
    //////////////////////////////////////////////////////////////*/

    function testPause() public {
        vm.prank(owner);
        nft.pause();
        assertTrue(nft.paused());
    }

    function testPauseNotAdmin() public {
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                LibString.toHexString(alice),
                " is missing role ",
                LibString.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.prank(alice);
        nft.pause();
    }

    function testUnpause() public {
        vm.prank(owner);
        nft.pause();
        assertTrue(nft.paused());

        vm.prank(owner);
        nft.unpause();
        assertFalse(nft.paused());
    }

    function testUnpauseNotAdmin() public {
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                LibString.toHexString(alice),
                " is missing role ",
                LibString.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.prank(alice);
        nft.unpause();
    }

    /*//////////////////////////////////////////////////////////////
                        SET BASE URI
    //////////////////////////////////////////////////////////////*/

    function testSetBaseURI() public {
        string memory uri = "https://newuri.com/";
        uint256 tokenId = 1;
        string memory expectedURI = "https://newuri.com/1";

        vm.prank(owner);
        nft.mint(alice);

        vm.expectEmit(true, true, true, true);
        emit BaseTokenURISet(uri);

        vm.prank(owner);
        nft.setBaseTokenURI(uri);
        assertEq(nft.tokenURI(tokenId), expectedURI);
    }

    function testSetBaseURINotAdmin() public {
        string memory uri = "https://newuri.com/";

        vm.prank(owner);
        nft.mint(alice);

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                LibString.toHexString(alice),
                " is missing role ",
                LibString.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.prank(alice);
        nft.setBaseTokenURI(uri);
    }
}
