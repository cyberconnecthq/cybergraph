// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployVault is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();
        if (
            block.chainid == DeploySetting.OPTIMISM ||
            block.chainid == DeploySetting.OP_GOERLI ||
            block.chainid == DeploySetting.OP_SEPOLIA
        ) {
            LibDeploy.deployVault(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.treasuryReceiver,
                deployParams.backendSigner
            );
        }
        vm.stopBroadcast();
    }
}

contract UpgradeVault is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();
        if (block.chainid == DeploySetting.OP_SEPOLIA) {
            LibDeploy.upgradeVault(
                vm,
                deployParams.deployerContract,
                0x5254857780901d6cc80E42946a7D101FE8667EA8
            );
        } else if (block.chainid == DeploySetting.OPTIMISM) {
            LibDeploy.upgradeVault(
                vm,
                deployParams.deployerContract,
                0x5b3A81f9B29E51518316B4E2B8FD5986a3785CA4
            );
        }
        vm.stopBroadcast();
    }
}
