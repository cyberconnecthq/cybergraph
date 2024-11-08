// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract UpgradeCyberNFT is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();
        if (block.chainid == DeploySetting.CYBER_TESTNET) {
            LibDeploy.upgradeCyberNFT(
                vm,
                deployParams.deployerContract,
                0x60A1b9c6900C6cEF0e08B939cc00635Ad7DF02a1
            );
        } else if (block.chainid == DeploySetting.CYBER) {
            LibDeploy.upgradeCyberNFT(
                vm,
                deployParams.deployerContract,
                0x60A1b9c6900C6cEF0e08B939cc00635Ad7DF02a1
            );
        }
        vm.stopBroadcast();
    }
}
