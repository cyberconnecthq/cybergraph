// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { CyberNFT721 } from "../base/CyberNFT721.sol";

contract Soul is CyberNFT721 {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    bool private _initialized;

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function initialize(string calldata name, string calldata symbol) external {
        require(_initialized == false, "ALREADY_INITIALIZED");
        _initialized = true;

        super._initialize(name, symbol);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Disallows the transfer of the essence nft.
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        revert("TRANSFER_NOT_ALLOWED");
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Generates the metadata json object.
     *
     * @param tokenId The profile NFT token ID.
     * @return string The metadata json object.
     * @dev It requires the tokenId to be already minted.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        // TODO: tokenURI
        return "";
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _mint(address to) internal override returns (uint256) {
        return super._mint(to);
    }
}
