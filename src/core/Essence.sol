// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IEssence } from "../interfaces/IEssence.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { IDeployer } from "../interfaces/IDeployer.sol";

import { CyberNFT721 } from "../base/CyberNFT721.sol";
import { LibString } from "../libraries/LibString.sol";

/**
 * @title Essence NFT
 * @author CyberConnect
 * @notice This contract is used to create an Essence NFT.
 */
contract Essence is CyberNFT721, IEssence {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    address public immutable ENGINE;

    address internal _account;
    uint256 internal _essenceId;
    bool internal _transferable;

    bool private _initialized;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        address engine = IDeployer(msg.sender).params();
        require(engine != address(0), "ZERO_ADDRESS");

        ENGINE = engine;
        _initialized = true;
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEssence
    function mint(address to) external override returns (uint256) {
        require(msg.sender == ENGINE, "ONLY_ENGINE");
        return super._mint(to);
    }

    /// @inheritdoc IEssence
    function initialize(
        address account,
        uint256 essenceId,
        string calldata name,
        string calldata symbol,
        bool transferable
    ) external override {
        require(_initialized == false, "ALREADY_INITIALIZED");
        _initialized = true;

        _account = account;
        _essenceId = essenceId;
        _transferable = transferable;

        super._initialize(name, symbol);
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
     * @param tokenId The EssenceNFT token ID.
     * @return string The metadata json object.
     * @dev It requires the tokenId to be already minted.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory uri = ICyberEngine(ENGINE).getEssenceTokenURI(
            _account,
            _essenceId
        );
        return string(abi.encodePacked(uri, LibString.toString(tokenId)));
    }
}
