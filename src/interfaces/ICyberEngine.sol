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
}
