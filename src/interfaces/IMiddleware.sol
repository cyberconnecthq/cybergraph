// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

/**
 * @title IMiddleware
 * @author CyberConnect
 */
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
     * @param params The middleware related params.
     */
    function preProcess(DataTypes.MwParams calldata params) external;
}
