// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { ERC721 } from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC721Burnable } from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { Pausable } from "openzeppelin-contracts/contracts/security/Pausable.sol";

import { EIP712 } from "../base/EIP712.sol";
import { IWorkInCryptoNFT } from "../interfaces/IWorkInCryptoNFT.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

/**
 * @title WorkInCryptoNFT
 * @author CyberConnect
 * @notice This contract is the NFT for IWorthInCrypto Campaign.
 */
contract WorkInCryptoNFT is
    AccessControl,
    EIP712,
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Pausable,
    IWorkInCryptoNFT
{
    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Token URI prefix.
     */
    string public baseTokenURI;

    /**
     * @notice The current index of the token.
     */
    uint256 internal _currentIndex;

    /**
     * @notice The address of the signer.
     */
    address internal _signer;

    /**
     * @notice Nonces for each address.
     */
    mapping(address => uint256) internal _nonces;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    bytes32 internal constant _MINTER_ROLE = keccak256(bytes("MINTER_ROLE"));

    bytes32 internal constant _MINT_TYPEHASH =
        keccak256("mint(address to,uint256 nonce,uint256 deadline)");

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTORS 
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        address owner,
        address signer
    ) ERC721(name, symbol) {
        _signer = signer;
        baseTokenURI = uri;
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(_MINTER_ROLE, owner);
        _grantRole(_MINTER_ROLE, signer);
    }

    /*//////////////////////////////////////////////////////////////
                                MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint a token to the given address. Only minter can call this function.
     */
    function mint(address to) external virtual onlyRole(_MINTER_ROLE) {
        _mint(to);
    }

    /**
     * @notice Mint a token to the given address with a EIP-712 signature.
     */
    function mintWithSig(
        address to,
        DataTypes.EIP712Signature calldata sig
    ) external {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(_MINT_TYPEHASH, to, _nonces[to]++, sig.deadline)
                )
            ),
            _signer,
            sig
        );

        _mint(to);
    }

    /**
     * @notice Set the signer address.
     */
    function setSigner(address signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _signer = signer;
        _grantRole(_MINTER_ROLE, signer);
    }

    /**
     * @notice Pauses all token transfers.
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses all token transfers.
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Set the base token uri.
     */
    function setBaseTokenURI(
        string calldata uri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = uri;
        emit BaseTokenURISet(uri);
    }

    /**
     * @notice Returns the nonce for the given account.
     */
    function getNonce(address account) external view returns (uint256) {
        return _nonces[account];
    }

    /**
     * @notice Returns the signer address.
     */
    function getSinger() external view returns (address) {
        return _signer;
    }

    /*//////////////////////////////////////////////////////////////
                                EIP-712
    //////////////////////////////////////////////////////////////*/

    function _domainSeparatorName()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return "WorkInCryptoNFT";
    }

    function _mint(address _to) internal virtual returns (uint256) {
        super._safeMint(_to, ++_currentIndex);
        return _currentIndex;
    }

    /*//////////////////////////////////////////////////////////////
                            ERC-721 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /*//////////////////////////////////////////////////////////////
                            ERC-165 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return
            ERC721Enumerable.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}
