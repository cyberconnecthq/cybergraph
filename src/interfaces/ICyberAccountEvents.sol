// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @title ICyberAccountEvents
 * @author CyberConnect
 */
interface ICyberAccountEvents {
    /**
     * @notice Emitted when a CyberAccount is initialized.
     * @param entryPoint The entry point.
     * @param owner The owner of the CyberAccount.
     */
    event CyberAccountInitialized(
        IEntryPoint indexed entryPoint,
        address indexed owner
    );
}
