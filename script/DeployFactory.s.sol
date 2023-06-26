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
                address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789)
            );
        } else if (block.chainid == DeploySetting.OP_GOERLI) {
            LibDeploy.deployFactory(
                vm,
                deployParams.deployerContract,
                address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789)
            );
        }
        vm.stopBroadcast();
    }
}
