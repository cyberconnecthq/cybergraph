// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberEngineEvents {
    /**
     * @notice Emitted when a new essence been created.
     *
     * @param account The account address.
     * @param essenceId The essence id.
     * @param name The essence name.
     * @param symbol The essence symbol.
     * @param tokenURI the essence tokenURI.
     * @param essence the deployed EssenceNFT address.
     * @param mw The middleware.
     */
    event RegisterEssence(
        address indexed account,
        uint256 indexed essenceId,
        string name,
        string symbol,
        string tokenURI,
        address mw,
        address essence
    );

    /**
     * @notice Emitted when a new content been created.
     *
     * @param account The account address.
     * @param tokenId The token id.
     * @param tokenURI the content tokenURI.
     * @param content the deployed ContentNFT address.
     * @param mw The middleware.
     */
    event PublishContent(
        address indexed account,
        uint256 indexed tokenId,
        string tokenURI,
        address mw,
        address content
    );

    /**
     * @notice Emitted when a new share been created.
     *
     * @param account The account address.
     * @param tokenId The token id.
     * @param srcAccount the src account to share.
     * @param srcId the src id to share
     */
    event Share(
        address indexed account,
        uint256 indexed tokenId,
        address srcAccount,
        uint256 srcId
    );

    /**
     * @notice Emitted when a new w3st been created.
     *
     * @param account The account address.
     * @param tokenId The token id.
     * @param tokenURI the content tokenURI.
     * @param w3st the deployed W3ST address.
     * @param mw The middleware.
     */
    event IssueW3st(
        address indexed account,
        uint256 indexed tokenId,
        string tokenURI,
        address mw,
        address w3st
    );

    /**
     * @notice Emitted when an essence has been collected.
     *
     * @param collector The collector address.
     * @param account The account addresss.
     * @param id The id.
     * @param amount The amount to collect.
     * @param newTokenId The token id of the newly minted NFT (only for collecting Essence).
     * @param category The category to collect.
     * @param data The collect data for preprocess.
     */
    event Collect(
        address indexed collector,
        address indexed account,
        uint256 indexed id,
        uint256 amount,
        uint256 newTokenId,
        DataTypes.Category category,
        bytes data
    );

    /**
     * @notice Emitted when essence data has been set to an account.
     *
     * @param account The account address.
     * @param essenceId The essence id.
     * @param tokenURI The new token URI.
     * @param mw The new middleware.
     */
    event SetEssenceData(
        address indexed account,
        uint256 indexed essenceId,
        string tokenURI,
        address mw
    );

    /**
     * @notice Emitted when content data has been set to an account.
     *
     * @param account The account address.
     * @param tokenId The token id.
     * @param tokenURI The new token URI.
     * @param mw The new middleware.
     */
    event SetContentData(
        address indexed account,
        uint256 indexed tokenId,
        string tokenURI,
        address mw
    );

    /**
     * @notice Emitted when w3st data has been set to an account.
     *
     * @param account The account address.
     * @param tokenId The token id.
     * @param tokenURI The new token URI.
     * @param mw The new middleware.
     */
    event SetW3stData(
        address indexed account,
        uint256 indexed tokenId,
        string tokenURI,
        address mw
    );
}
