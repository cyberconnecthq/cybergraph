// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberEngineEvents } from "./ICyberEngineEvents.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberEngine is ICyberEngineEvents {
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
}
