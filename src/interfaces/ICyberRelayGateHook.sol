// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

struct RelayParams {
    address to;
    uint256 value;
    bytes callData;
}

/**
 * @title ICyberRelayGateHook
 * @author Cyber
 */
interface ICyberRelayGateHook {
    function processRelay(
        address msgSender,
        address destination,
        bytes calldata data
    ) external payable returns (RelayParams memory);
}
