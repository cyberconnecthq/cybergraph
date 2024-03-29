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
 * @notice This contract defines Essence NFT in CyberConnect Protocol.
 */
contract Essence is CyberNFT721, IEssence {
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

    constructor() {
        address engine = IDeployer(msg.sender).params();
        require(engine != address(0), "ZERO_ADDRESS");

        ENGINE = engine;
        _disableInitializers();
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
    ) external override initializer {
        _account = account;
        _essenceId = essenceId;
        _transferable = transferable;

        super._initialize(name, symbol);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEssence
    function isTransferable() external view override returns (bool) {
        return _transferable;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// ERC721
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

    /// ERC721
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
