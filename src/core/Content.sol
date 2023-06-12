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
 * @notice This contract is used to create an Content NFT.
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

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

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

    // todo support batch transfer?

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    function uri(
        uint256 id
    ) public view virtual override returns (string memory) {
        return ICyberEngine(ENGINE).getContentTokenURI(_account, id);
    }
}
