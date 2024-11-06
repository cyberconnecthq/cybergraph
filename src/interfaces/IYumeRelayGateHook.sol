// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

struct RelayParams {
    address to;
    uint256 value;
    bytes callData;
}

/**
 * @title IYumeRelayGateHook
 * @author Cyber
 */
interface IYumeRelayGateHook {
    function processRelay(
        address msgSender,
        uint256 chainId,
        address entryPoint,
        bytes calldata data
    ) external payable returns (RelayParams memory);
}
