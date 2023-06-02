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

    /**
     * @notice Initializes the Essence NFT.
     *
     * @param account The account address for the Essence NFT.
     * @param essenceId The essence ID for the Essence NFT.
     * @param name The name for the Essence NFT.
     * @param symbol The symbol for the Essence NFT.
     * @param transferable Whether the Essence NFT is transferable.
     */
    function initialize(
        address account,
        uint256 essenceId,
        string calldata name,
        string calldata symbol,
        bool transferable
    ) external;
}
