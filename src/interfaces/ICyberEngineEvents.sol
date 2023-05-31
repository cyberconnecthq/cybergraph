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
     * @param mw The essence middleware.
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
}
