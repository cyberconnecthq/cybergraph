// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployMw is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.MUMBAI) {
            LibDeploy.deployMw(
                vm,
                deployParams.deployerContract,
                address(0x0FD51A4bf0f885496a41db946Bd9a5cCCd69b771)
            );
        }
        vm.stopBroadcast();
    }
}
