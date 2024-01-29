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
