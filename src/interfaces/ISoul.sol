// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ISoulEvents } from "./ISoulEvents.sol";

interface ISoul is ISoulEvents {
    function createSoul(address to, bool isOrg) external returns (uint256);

    function setOrg(address account, bool isOrg) external;

    function isOrgAccount(address account) external view returns (bool);
}
