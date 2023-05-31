// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IEssence {
    /**
     * @notice Mints the Essence.
     *
     * @param to The recipient address.
     * @return uint256 The token id.
     */
    function mint(address to) external returns (uint256);

    /**
     * @notice Check if this essence NFT is transferable.
     *
     * @return bool Whether this Essence NFT is transferable.
     */
    function isTransferable() external returns (bool);
}
