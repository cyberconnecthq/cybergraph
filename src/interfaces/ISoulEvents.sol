// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ISoulEvents {
    event CreateSoul(
        address indexed to,
        bool indexed isOrg,
        uint256 indexed tokenId
    );

    event SetOrg(address indexed account, bool indexed isOrg);
}
