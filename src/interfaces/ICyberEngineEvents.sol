// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

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
     * @notice Emitted when a new essence been created.
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
     * @notice Emitted when an essence has been collected.
     *
     * @param collector The collector address.
     * @param account The account addresss.
     * @param essenceId The essence id.
     * @param tokenId The token id of the newly minted essent NFT.
     * @param data The collect data for preprocess.
     */
    event CollectEssence(
        address indexed collector,
        address indexed account,
        uint256 indexed essenceId,
        uint256 tokenId,
        bytes data
    );

    /**
     * @notice Emitted when a essence middleware has been set to an account.
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
}
