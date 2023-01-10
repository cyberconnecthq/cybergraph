// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

contract CyberWallet {
    address public entryPoint;

    constructor(address _entryPoint) {
        require(_entryPoint != address(0));
        entryPoint = _entryPoint;
    }

    function execTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) public virtual {
        require(msg.sender == entryPoint);
        _execute(to, value, data, gasleft());
    }

    function _execute(
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
