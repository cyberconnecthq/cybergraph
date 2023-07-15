// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployAll is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (
            block.chainid == DeploySetting.MUMBAI ||
            block.chainid == DeploySetting.BASE_GOERLI ||
            block.chainid == DeploySetting.POLYGON
        ) {
            LibDeploy.deployAll(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.treasuryReceiver,
                deployParams.protocolOwner,
                deployParams.entryPoint,
                deployParams.backendSigner,
                true
            );
        }
        vm.stopBroadcast();
    }
}
