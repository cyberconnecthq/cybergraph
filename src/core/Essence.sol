// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IEssence } from "../interfaces/IEssence.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";

import { CyberNFT721 } from "../base/CyberNFT721.sol";

/**
 * @title Essence NFT
 * @author CyberConnect
 * @notice This contract is used to create an Essence NFT.
 */
contract EssenceNFT is CyberNFT721, IEssence {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    address public immutable ENGINE;

    address internal _account;
    uint256 internal _essenceId;
    bool internal _transferable;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address account,
        uint256 essenceId,
        string memory name,
        string memory symbol,
        address engine,
        bool transferable
    ) CyberNFT721(name, symbol) {
        _account = account;
        _essenceId = essenceId;
        _transferable = transferable;
        ENGINE = engine;
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEssence
    function mint(address to) external override returns (uint256) {
        require(msg.sender == ENGINE, "ONLY_ENGINE");
        return super._mint(to);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    // @inheritdoc IEssence
    function isTransferable() external view override returns (bool) {
        return _transferable;
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
        if (!_transferable) {
            revert("TRANSFER_NOT_ALLOWED");
        }
        super.transferFrom(from, to, id);
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
        return ICyberEngine(ENGINE).getEssenceTokenURI(_account, _essenceId);
    }
}
