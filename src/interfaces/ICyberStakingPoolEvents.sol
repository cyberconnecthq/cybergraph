// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

/**
 * @title ICyberStakingPoolEvents
 * @author CyberConnect
 */
interface ICyberStakingPoolEvents {
    /**
     * @notice Emitted when a deposit has been made.
     *
     * @param logId The log id which helps to deduplicate logs.
     * @param assetOwner The address deposit to.
     * @param asset The asset address.
     * @param amount The deposit amount.
     */
    event Deposit(
        uint256 logId,
        address assetOwner,
        address asset,
        uint256 amount
    );

    /**
     * @notice Emitted when a withdraw has been made.
     *
     * @param logId The log id which helps to deduplicate logs.
     * @param assetOwner The address withdraw from.
     * @param assets The asset addresses.
     * @param amounts The withdraw amounts.
     */
    event Withdraw(
        uint256 logId,
        address assetOwner,
        address[] assets,
        uint256[] amounts
    );

    /**
     * @notice Emitted when a bridge has been made.
     *
     * @param logId The log id which helps to deduplicate logs.
     * @param bridge The bridge address.
     * @param assetOwner The address bridge from.
     * @param recipient The address bridge to.
     * @param assets The asset addresses.
     * @param amounts The bridge amounts.
     */
    event Bridge(
        uint256 logId,
        address bridge,
        address assetOwner,
        address recipient,
        address[] assets,
        uint256[] amounts
    );

    /**
     * @notice Emitted when a asset whitelist has been set.
     *
     * @param asset The asset address.
     * @param isWhitelisted The whitelist status.
     */
    event SetAssetWhitelist(address asset, bool isWhitelisted);

    /**
     * @notice Emitted when a bridge whitelist has been set.
     *
     * @param bridge The bridge address.
     * @param isWhitelisted The whitelist status.
     */
    event SetBridgeWhitelist(address bridge, bool isWhitelisted);
}
