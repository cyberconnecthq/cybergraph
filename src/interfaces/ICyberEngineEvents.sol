// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

/**
 * @title ICyberEngineEvents
 * @author CyberConnect
 */
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
     * @notice Emitted when a new Subscription been registered.
     *
     * @param account The account address.
     * @param name The subscription name.
     * @param symbol The subscription symbol.
     * @param tokenURI the subscription tokenURI.
     * @param pricePerSub The price per subscription.
     * @param dayPerSub The day per subscription.
     * @param recipient The recipient address.
     * @param subscribe The subscribe NFT contract address.
     */
    event RegisterSubscription(
        address indexed account,
        string name,
        string symbol,
        string tokenURI,
        uint256 pricePerSub,
        uint256 dayPerSub,
        address recipient,
        address subscribe
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
     * @notice Emitted when a new comment been created.
     *
     * @param account The account address.
     * @param tokenId The token id.
     * @param tokenURI the content tokenURI.
     * @param content the deployed ContentNFT address.
     * @param mw The middleware.
     * @param accountCommented The commented account address.
     * @param idCommented The commented token id.
     */
    event Comment(
        address indexed account,
        uint256 indexed tokenId,
        string tokenURI,
        address mw,
        address content,
        address accountCommented,
        uint256 idCommented
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

    /**
     * @notice Emitted when subscription data has been set to an account.
     *
     * @param account The account address.
     * @param tokenURI The new token URI.
     * @param recipient The new recipient address.
     * @param pricePerSub The new price per subscription.
     * @param dayPerSub The new day per subscription.
     */
    event SetSubscriptionData(
        address indexed account,
        string tokenURI,
        address recipient,
        uint256 pricePerSub,
        uint256 dayPerSub
    );

    /**
     * @notice Emitted when a new operator been approved.
     *
     * @param account The account address.
     * @param operator The operator address.
     * @param approved The approval status.
     */
    event SetOperatorApproval(
        address indexed account,
        address indexed operator,
        bool prevApproved,
        bool approved
    );
}
