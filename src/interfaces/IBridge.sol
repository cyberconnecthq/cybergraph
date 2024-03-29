// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

/**
 * @title IBridge
 * @author CyberConnect
 */
interface IBridge {
    /**
     * @notice Bridges asset to Cyber L2.
     *
     * @param assetOwner The owner of the asset.
     * @param recipient The recipient of the asset.
     * @param assets The assets to bridge.
     * @param amounts The amounts to bridge.
     */
    function bridge(
        address assetOwner,
        address recipient,
        address[] calldata assets,
        uint256[] calldata amounts
    ) external;
}
