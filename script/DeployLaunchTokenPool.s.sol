// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployLaunchTokenPool is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.BNBT) {
            LibDeploy.deployLaunchTokenPool(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                0x0000000000000000000000000000000000000000 // token address
            );
        }
        vm.stopBroadcast();
    }
}
