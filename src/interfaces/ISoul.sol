// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ISoulEvents } from "./ISoulEvents.sol";

/**
 * @title ISoul
 * @author CyberConnect
 */
interface ISoul is ISoulEvents {
    /**
     * @notice Creates a soul.
     *
     * @param to The recipient address.
     * @param isOrg Whether the soul is an organization.
     * @return uint256 The soul token ID.
     */
    function createSoul(address to, bool isOrg) external returns (uint256);

    /**
     * @notice Sets if a soul is a organization.
     *
     * @param account The soul owner address.
     * @param isOrg Whether the soul is an organization.
     */
    function setOrg(address account, bool isOrg) external;

    /**
     * @notice Checks if a soul is an organization.
     *
     * @param account The soul owner address.
     * @return bool Whether the soul is an organization.
     */
    function isOrgAccount(address account) external view returns (bool);

    /**
     * @notice Set the Soul token URI
     *
     * @param uri The new tokenURI
     */
    function setTokenURI(string calldata uri) external;
}
