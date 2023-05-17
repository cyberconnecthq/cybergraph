// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberAccountEvents } from "./ICyberAccountEvents.sol";

interface ICyberAccount is ICyberAccountEvents {
    function execute(address dest, uint256 value, bytes calldata func) external;

    function executeBatch(
        address[] calldata dest,
        bytes[] calldata func
    ) external;
}
