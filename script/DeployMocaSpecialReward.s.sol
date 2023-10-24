// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployMocaSpecialReward is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.POLYGON) {
            LibDeploy.deploySpecialReward(
                vm,
                0x675bCca5A5517bF3D047417Af7a1100bBd3F31D1,
                "https://metadata.cyberconnect.dev/essence/3c3e53132d05b240",
                "MocaSpecialReward"
            );
        }
        vm.stopBroadcast();
    }
}
