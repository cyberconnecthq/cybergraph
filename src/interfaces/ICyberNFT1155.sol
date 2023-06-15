// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

/**
 * @title ICyberNFT1155
 * @author CyberConnect
 */
interface ICyberNFT1155 {
    /**
     * @notice Gets total supply for certain tokenID, burned tokens will reduce the count.
     *
     * @param tokenId The token ID to check.
     * @return uint256 The total supply.
     */
    function totalSupply(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Gets total supply for all, burned tokens will reduce the count.
     *
     * @return uint256 The total supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Burns a token.
     *
     * @param account The account address to burn.
     * @param tokenId The token ID to burn.
     * @param amount The amount to burn.
     */
    function burn(address account, uint256 tokenId, uint256 amount) external;

    /**
     * @notice Batch burn token.
     *
     * @param account The account address to burn.
     * @param tokenIds The token IDs to burn.
     * @param amounts The amounts to burn.
     */
    function burnBatch(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;
}
