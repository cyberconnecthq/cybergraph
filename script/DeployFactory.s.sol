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
                deployParams.deployerContract,
                deployParams.entryPoint,
                address(0x950453Fdc75510e250806769A342F3129E3C3Fad) // soul address
            );
        } else if (block.chainid == DeploySetting.OP_GOERLI) {
            LibDeploy.deployFactory(
                vm,
                deployParams.deployerContract,
                deployParams.entryPoint,
                address(0x950453Fdc75510e250806769A342F3129E3C3Fad) // soul address
            );
        }
        vm.stopBroadcast();
    }
}
