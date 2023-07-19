// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployTimeLock is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.POLYGON) {
            address timelock = LibDeploy.deployTimeLock(
                vm,
                deployParams.protocolSafe,
                48 * 3600,
                true
            );
        }
        vm.stopBroadcast();
    }
}
