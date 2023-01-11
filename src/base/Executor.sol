// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

contract Executor {
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    ) internal returns (bool success) {
        assembly {
            success := call(
                txGas,
                to,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
    }
}
