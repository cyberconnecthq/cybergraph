// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract MetadataResolver {
    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint64 => mapping(uint256 => mapping(string => string))) _metadatas;
    mapping(uint256 => uint64) public metadataVersions;

    mapping(uint64 => mapping(uint256 => mapping(string => string))) _gatedMetadatas;
    mapping(uint256 => uint64) public gatedMetadataVersions;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event MetadataVersionChanged(uint256 indexed tokenId, uint64 newVersion);

    event MetadataChanged(uint256 indexed tokenId, string key, string value);

    event GatedMetadataVersionChanged(
        uint256 indexed tokenId,
        uint64 newVersion
    );

    event GatedMetadataChanged(
        uint256 indexed tokenId,
        string key,
        string value
    );

    /*//////////////////////////////////////////////////////////////
                            MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier authorised(uint256 tokenId) {
        require(_isMetadataAuthorised(tokenId), "METADATA_UNAUTHORISED");
        _;
    }

    modifier gatedAuthorised(uint256 tokenId) {
        require(
            _isGatedMetadataAuthorised(tokenId),
            "GATED_METADATA_UNAUTHORISED"
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Clears all metadata on a token.
     * @param   tokenId  token to clear metadata.
     */
    function clearMetadatas(
        uint256 tokenId
    ) external virtual authorised(tokenId) {
        _clearMetadatas(tokenId);
    }

    /**
     * @notice  Clears all gated metadata on a token.
     * @param   tokenId  token to clear metadata.
     */
    function clearGatedMetadatas(
        uint256 tokenId
    ) external virtual gatedAuthorised(tokenId) {
        _clearGatedMetadatas(tokenId);
    }

    /**
     * @notice Sets the metadatas associated with an token and keys.
     * Only can be called by the owner or approved operators of that token.
     * @param tokenId The token to update.
     * @param pairs The kv pairs to set.
     */
    function batchSetMetadatas(
        uint256 tokenId,
        DataTypes.MetadataPair[] calldata pairs
    ) external authorised(tokenId) {
        for (uint256 i = 0; i < pairs.length; i++) {
            DataTypes.MetadataPair memory pair = pairs[i];
            _metadatas[metadataVersions[tokenId]][tokenId][pair.key] = pair
                .value;
            emit MetadataChanged(tokenId, pair.key, pair.value);
        }
    }

    /**
     * @notice Sets the gated metadatas associated with an token and keys.
     * @param tokenId The token to update.
     * @param pairs The kv pairs to set.
     */
    function batchSetGatedMetadatas(
        uint256 tokenId,
        DataTypes.MetadataPair[] calldata pairs
    ) public gatedAuthorised(tokenId) {
        for (uint256 i = 0; i < pairs.length; i++) {
            DataTypes.MetadataPair memory pair = pairs[i];
            _gatedMetadatas[gatedMetadataVersions[tokenId]][tokenId][
                pair.key
            ] = pair.value;
            emit GatedMetadataChanged(tokenId, pair.key, pair.value);
        }
    }

    /**
     * @notice Returns the metadata associated with an token and key.
     * @param tokenId The token to query.
     * @param key The metadata key to query.
     * @return The associated metadata.
     */
    function getMetadata(
        uint256 tokenId,
        string calldata key
    ) external view returns (string memory) {
        return _metadatas[metadataVersions[tokenId]][tokenId][key];
    }

    /**
     * @notice Returns the gated metadata associated with an token and key.
     * @param tokenId The token to query.
     * @param key The metadata key to query.
     * @return The associated metadata.
     */
    function getGatedMetadata(
        uint256 tokenId,
        string memory key
    ) public view returns (string memory) {
        return _gatedMetadatas[gatedMetadataVersions[tokenId]][tokenId][key];
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _isMetadataAuthorised(
        uint256 tokenId
    ) internal view virtual returns (bool);

    function _isGatedMetadataAuthorised(
        uint256 tokenId
    ) internal view virtual returns (bool);

    function _clearMetadatas(uint256 tokenId) internal virtual {
        metadataVersions[tokenId]++;
        emit MetadataVersionChanged(tokenId, metadataVersions[tokenId]);
    }

    function _clearGatedMetadatas(uint256 tokenId) internal virtual {
        gatedMetadataVersions[tokenId]++;
        emit GatedMetadataVersionChanged(
            tokenId,
            gatedMetadataVersions[tokenId]
        );
    }
}
