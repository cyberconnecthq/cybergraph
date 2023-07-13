// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "../../src/interfaces/IMiddleware.sol";
import "../../src/libraries/DataTypes.sol";

contract MockMiddleware is IMiddleware {
    mapping(address => mapping(DataTypes.Category => mapping(uint256 => bytes)))
        internal _mockData;

    function setMwData(
        address account,
        DataTypes.Category category,
        uint256 id,
        bytes calldata data
    ) external override {
        _mockData[account][category][id] = data;
    }

    function preProcess(
        DataTypes.MwParams calldata params
    ) external pure override {
        // do nothing
    }

    function getMwData(
        address account,
        DataTypes.Category category,
        uint256 id
    ) external view returns (bytes memory) {
        return _mockData[account][category][id];
    }
}
