// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberEngineEvents } from "./ICyberEngineEvents.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberEngine is ICyberEngineEvents {
    /**
     * @notice Collect an account's essence. Anyone can collect to another wallet
     *
     * @param params The params for collect.
     * @param data The collect data for preprocess.
     * @return uint256 The collected essence nft id.
     */
    function collect(
        DataTypes.CollectParams calldata params,
        bytes calldata data
    ) external returns (uint256);

    /**
     * @notice Register an essence.
     *
     * @param params The params for registration.
     * @param initData The registration initial data.
     * @return uint256 The new essence count.
     */
    function registerEssence(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData
    ) external returns (uint256);

    /**
     * @notice Publish a content.
     *
     * @param params The params for publishing content.
     * @param initData The registration initial data.
     * @return uint256 The new token id.
     */
    function publishContent(
        DataTypes.PublishContentParams calldata params,
        bytes calldata initData
    ) external returns (uint256);

    /**
     * @notice Share a content, comment or another share.
     *
     * @param params The params for sharing.
     * @return uint256 The new token id.
     */
    function share(
        DataTypes.ShareParams calldata params
    ) external returns (uint256);

    /**
     * @notice Comment a content or share.
     *
     * @param params The params for commenting content.
     * @param initData The registration initial data.
     * @return uint256 The new token id.
     */
    function comment(
        DataTypes.CommentParams calldata params,
        bytes calldata initData
    ) external returns (uint256);

    /**
     * @notice Issue a w3st.
     *
     * @param params The params for issuing w3st.
     * @param initData The registration initial data.
     * @return uint256 The new token id.
     */
    function issueW3st(
        DataTypes.IssueW3stParams calldata params,
        bytes calldata initData
    ) external returns (uint256);

    /**
     * @notice Gets the Essence NFT token URI.
     *
     * @param account The account address.
     * @param essenceId The Essence ID.
     * @return string The Essence NFT token URI.
     */
    function getEssenceTokenURI(
        address account,
        uint256 essenceId
    ) external view returns (string memory);

    function getEssenceTransferability(
        address account,
        uint256 tokenID
    ) external view returns (bool);

    /**
     * @notice Sets essence data.
     *
     * @param essenceId The essence ID.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     */
    function setEssenceData(
        uint256 essenceId,
        string calldata tokenURI,
        address mw,
        bytes calldata data
    ) external;

    function getEssenceAddr(
        address account,
        uint256 essenceId
    ) external view returns (address);

    function getEssenceMw(
        address account,
        uint256 essenceId
    ) external view returns (address);

    /**
     * @notice Sets content data.
     *
     * @param tokenId The content tokenId.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     */
    function setContentData(
        uint256 tokenId,
        string calldata tokenURI,
        address mw,
        bytes calldata data
    ) external;

    /**
     * @notice Sets w3st data.
     *
     * @param tokenId The w3st tokenId.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     */
    function setW3stData(
        uint256 tokenId,
        string calldata tokenURI,
        address mw,
        bytes calldata data
    ) external;

    function getContentTokenURI(
        address account,
        uint256 tokenID
    ) external view returns (string memory);

    function getContentAddr(address account) external view returns (address);

    function getContentTransferability(
        address account,
        uint256 tokenID
    ) external view returns (bool);

    function getContentSrcInfo(
        address account,
        uint256 tokenID
    ) external view returns (address, uint256);

    function getContentMw(
        address account,
        uint256 tokenID
    ) external view returns (address);

    function getW3stTokenURI(
        address account,
        uint256 tokenID
    ) external view returns (string memory);

    function getW3stAddr(address account) external view returns (address);

    function getW3stTransferability(
        address account,
        uint256 tokenID
    ) external view returns (bool);

    function getW3stMw(
        address account,
        uint256 tokenID
    ) external view returns (address);
}
