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
     * @return uint256 The soul token ID.
     */
    function createSoul(address to) external returns (uint256);

    /**
     * @notice Sets if a soul is a organization.
     *
     * @param account The soul owner address.
     * @param isOrg Whether the soul is an organization.
     */
    function setOrg(address account, bool isOrg) external;

    /**
     * @notice Sets minter role.
     *
     * @param account The minter address.
     * @param isMinter Whether the account is a minter.
     */
    function setMinter(address account, bool isMinter) external;

    /**
     * @notice Checks if a soul is an organization.
     *
     * @param account The soul owner address.
     * @return bool Whether the soul is an organization.
     */
    function isOrgAccount(address account) external view returns (bool);

    /**
     * @notice Checks if an address is a minter.
     *
     * @param account The address to check.
     * @return bool Whether the address is a minter.
     */
    function isMinter(address account) external view returns (bool);

    /**
     * @notice Set the Soul token URI
     *
     * @param uri    The new tokenURI
     */
    function setTokenURI(string calldata uri) external;
}
