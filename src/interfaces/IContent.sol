// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

/**
 * @title IContent
 * @author CyberConnect
 */
interface IContent {
    /**
     * @notice Initialize the contract.
     * @param account The Content creator.
     */
    function initialize(address account) external;

    /**
     * @notice Mint a new token.
     * @param to The address to mint to.
     * @param id The token ID to mint.
     * @param amount The amount to mint.
     * @param data The data to pass if receiver is a contract.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @notice Check if the token is transferable.
     * @param tokenId The token ID to check.
     * @return True if the token is transferable.
     */
    function isTransferable(uint256 tokenId) external view returns (bool);
}
