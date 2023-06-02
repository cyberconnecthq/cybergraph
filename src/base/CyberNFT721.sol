// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC721 } from "../dependencies/solmate/ERC721.sol";

import { ICyberNFT721 } from "../interfaces/ICyberNFT721.sol";

/**
 * @title Cyber NFT Base
 * @author CyberConnect
 * @notice This contract is the base for all NFT contracts.
 */
abstract contract CyberNFT721 is ERC721, ICyberNFT721 {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/
    uint256 internal _currentIndex;
    uint256 internal _totalSupply;

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberNFT721
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberNFT721
    function burn(uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(
            msg.sender == owner ||
                msg.sender == getApproved[tokenId] ||
                isApprovedForAll[owner][msg.sender],
            "NOT_OWNER_OR_APPROVED"
        );
        super._burn(tokenId);
        _totalSupply--;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _initialize(
        string calldata name,
        string calldata symbol
    ) internal {
        ERC721.__ERC721_Init(name, symbol);
    }

    function _mint(address _to) internal virtual returns (uint256) {
        super._safeMint(_to, ++_currentIndex);
        _totalSupply++;
        return _currentIndex;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "NOT_MINTED");
    }
}
