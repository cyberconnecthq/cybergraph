// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IWalletEvents {
    /**
     * @notice Emitted when a new owner has been set.
     *
     * @param newOwner The newly set owner address.
     */
    event SetOwner(address indexed newOwner);

    /**
     * @notice Emitted when a new guardian module has been set.
     *
     * @param newGuardianModule The newly set module address.
     */
    event SetGuardianModule(address indexed newGuardianModule);
}
