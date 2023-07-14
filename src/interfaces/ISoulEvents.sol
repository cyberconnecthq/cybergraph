// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

/**
 * @title ISoulEvents
 * @author CyberConnect
 */
interface ISoulEvents {
    /**
     * @notice Emitted when a soul is created.
     *
     * @param to The recipient address.
     * @param isOrg Whether the soul is an organization.
     * @param tokenId The soul token ID.
     */
    event CreateSoul(
        address indexed to,
        bool indexed isOrg,
        uint256 indexed tokenId
    );

    /**
     * @notice Emitted when a soul is set/unset as an organization.
     *
     * @param account The soul owner address.
     * @param isOrg Whether the soul is an organization.
     */
    event SetOrg(address indexed account, bool indexed isOrg);

    /**
     * @notice Emitted when an address is set/unset as a minter.
     *
     * @param account The address.
     * @param isMinter Whether the address is a minter.
     */
    event SetMinter(address indexed account, bool indexed isMinter);
}
