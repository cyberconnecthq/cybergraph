// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployFactory is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.MUMBAI) {
            LibDeploy.deployFactory(
                vm,
                address(0x1306b01bC3e4AD202612D3843387e94737673F53)
            );
        }
        vm.stopBroadcast();
    }
}
