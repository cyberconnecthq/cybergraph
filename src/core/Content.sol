// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IContent } from "../interfaces/IContent.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { IDeployer } from "../interfaces/IDeployer.sol";

import { CyberNFT1155 } from "../base/CyberNFT1155.sol";
import { LibString } from "../libraries/LibString.sol";

/**
 * @title Content NFT
 * @author CyberConnect
 * @notice This contract defines Content NFT in CyberConnect Protocol.
 */
contract Content is CyberNFT1155, IContent {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    address public immutable ENGINE;

    address internal _account;

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

    /// @inheritdoc IContent
    function initialize(address account) external override initializer {
        _account = account;
    }

    /// @inheritdoc IContent
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external override {
        require(msg.sender == ENGINE, "ONLY_ENGINE");
        return super._mint(to, id, amount, data);
    }

    /// @inheritdoc IContent
    function isTransferable(
        uint256 tokenId
    ) external view override returns (bool) {
        return
            ICyberEngine(ENGINE).getContentTransferability(_account, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// ERC1155
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        if (!ICyberEngine(ENGINE).getContentTransferability(_account, id)) {
            revert("TRANSFER_NOT_ALLOWED");
        }

        super.safeTransferFrom(from, to, id, amount, data);
    }

    /// ERC1155
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            if (
                !ICyberEngine(ENGINE).getContentTransferability(
                    _account,
                    ids[i]
                )
            ) {
                revert("TRANSFER_NOT_ALLOWED");
            }
        }

        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /// ERC1155
    function uri(
        uint256 id
    ) public view virtual override returns (string memory) {
        return ICyberEngine(ENGINE).getContentTokenURI(_account, id);
    }
}
