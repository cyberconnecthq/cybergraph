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
                0xdb359A83ff0B91551161f12e9C5454CC04FA2fCc
            );
        } else if (block.chainid == DeploySetting.OP_SEPOLIA) {
            LibDeploy.deployLaunchTokenPool(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                0x1F765DC8b75D46786171A7967b99f1184D91b67B
            );
        }
        vm.stopBroadcast();
    }
}
