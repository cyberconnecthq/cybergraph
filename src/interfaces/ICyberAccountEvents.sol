// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

interface ICyberAccountEvents {
    event CyberAccountInitialized(
        IEntryPoint indexed entryPoint,
        address indexed owner
    );
}
