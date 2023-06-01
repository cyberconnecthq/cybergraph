// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IContent {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}
