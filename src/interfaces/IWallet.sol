// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IWalletEvents } from "./IWalletEvents.sol";

interface IWallet is IWalletEvents {
    /**
     * @notice Set new owner for Wallet.
     *
     * @param _newOwner New owner.
     */
    function setOwner(address _newOwner) external;

    /**
     * @notice Set new guardian module for Wallet.
     *
     * @param _newGuardianModule New owner.
     */
    function setGuardianModule(address _newGuardianModule) external;
}
