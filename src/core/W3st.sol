// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IW3st } from "../interfaces/IW3st.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";

import { CyberNFT1155 } from "../base/CyberNFT1155.sol";
import { LibString } from "../libraries/LibString.sol";

/**
 * @title W3st NFT
 * @author CyberConnect
 * @notice This contract is used to create an Essence NFT.
 */
contract W3st is CyberNFT1155, IW3st {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    address public immutable ENGINE;
    address internal _account;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address account, address engine) {
        require(engine != address(0), "ENGINE_NOT_SET");
        ENGINE = engine;
        _account = account;
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IW3st
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

        // todo do we need to check here?
        require(balanceOf[from][id] >= amount, "INSUFFICIENT_BALANCE");
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
