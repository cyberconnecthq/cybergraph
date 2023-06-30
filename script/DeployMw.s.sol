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
                address(0xEa2F6D76c6B9898Eaac94e9dde2f158cFc17d33B),
                address(0x4D9d3D16AefeE892537F453731F6C1d237153E17)
            );
        }
        vm.stopBroadcast();
    }
}
