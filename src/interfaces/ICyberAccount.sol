// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberAccountEvents } from "./ICyberAccountEvents.sol";

/**
 * @title ICyberAccount
 * @author CyberConnect
 */
interface ICyberAccount is ICyberAccountEvents {
    /**
     * @notice Execute a function call.
     * @param dest The destination address to call.
     * @param value The value to send.
     * @param func The function call data.
     */
    function execute(address dest, uint256 value, bytes calldata func) external;

    /**
     * @notice Execute a batch of function calls.
     * @param dest The destination addresses to call.
     * @param func The function call data.
     */
    function executeBatch(
        address[] calldata dest,
        bytes[] calldata func
    ) external;
}
