// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

/// Coinbase MetaPaymaster
/// See https://github.com/base-org/paymaster/pull/22
interface IMetaPaymaster {
    function fund(address target, uint256 amount) external;
}
