// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IYumeEngine {
    function relayCreateCollection(
        DataTypes.CreateTokenParams calldata createTokenParams,
        string calldata collectionName,
        address msgSender
    ) external returns (address);

    function relayCreateToken(
        address nft,
        DataTypes.CreateTokenParams calldata createTokenParams,
        address msgSender
    ) external returns (uint256);

    function mintWithEth(
        address nft,
        uint256 tokenId,
        address to,
        uint256 amount,
        address mintReferral,
        bytes calldata data
    ) external payable;
}
