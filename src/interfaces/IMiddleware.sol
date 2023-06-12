// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IMiddleware {
    /**
     * @notice Sets related data for middleware.
     *
     * @param account The account that owns this middleware.
     * @param category The category of target NFT.
     * @param id The corresponding identifer for a specific category.
     * @param data Extra data to set.
     */
    function setMwData(
        address account,
        DataTypes.Category category,
        uint256 id,
        bytes calldata data
    ) external;

    /**
     * @notice Process that runs before the NFT mint happens.
     *
     * @param account The account address.
     * @param category The category of target NFT.
     * @param id The corresponding identifier for a specific category.
     * @param collector The collector address.
     * @param referrerAccount The referrer account address.
     * @param data Extra data to process.
     */
    function preProcess(
        address account,
        DataTypes.Category category,
        uint256 id,
        address collector,
        address referrerAccount,
        bytes calldata data
    ) external;
}
