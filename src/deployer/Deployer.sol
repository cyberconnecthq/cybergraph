// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IDeployer } from "../interfaces/IDeployer.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

import { Essence } from "../core/Essence.sol";
import { Content } from "../core/Content.sol";
import { W3st } from "../core/W3st.sol";
import { Subscribe } from "../core/Subscribe.sol";

contract Deployer is IDeployer {
    DataTypes.DeployParameters public override params;

    /// @inheritdoc IDeployer
    function deployEssence(
        bytes32 salt,
        address engine
    ) external override returns (address addr) {
        params.engine = engine;
        addr = address(new Essence{ salt: salt }());
        delete params;
    }

    /// @inheritdoc IDeployer
    function deployContent(
        bytes32 salt,
        address engine
    ) external override returns (address addr) {
        params.engine = engine;
        addr = address(new Content{ salt: salt }());
        delete params;
    }

    /// @inheritdoc IDeployer
    function deployW3st(
        bytes32 salt,
        address engine
    ) external override returns (address addr) {
        params.engine = engine;
        addr = address(new W3st{ salt: salt }());
        delete params;
    }

    /// @inheritdoc IDeployer
    function deploySubscribe(
        bytes32 salt,
        address engine
    ) external override returns (address addr) {
        params.engine = engine;
        addr = address(new Subscribe{ salt: salt }());
        delete params;
    }
}
