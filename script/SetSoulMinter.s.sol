// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract SetSoulMinter is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.MUMBAI) {
            LibDeploy.setSoulMinter(
                vm,
                address(0x950453Fdc75510e250806769A342F3129E3C3Fad),
                address(0xfd65E94bC2dE0ceC83D8f65b39E24dAB11d7c558),
                true
            );
        }
        vm.stopBroadcast();
    }
}
