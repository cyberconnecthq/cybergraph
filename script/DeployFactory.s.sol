// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployFactory is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (
            block.chainid == DeploySetting.MUMBAI ||
            block.chainid == DeploySetting.BASE_GOERLI
        ) {
            LibDeploy.deployFactory(
                vm,
                deployParams.deployerContract,
                deployParams.entryPoint,
                address(0xf0BEbC0708b758ebfc329833a6063cC2195Fc725), // soul address
                deployParams.protocolOwner,
                true
            );
        } else if (block.chainid == DeploySetting.OP_GOERLI) {
            LibDeploy.deployFactory(
                vm,
                deployParams.deployerContract,
                deployParams.entryPoint,
                address(0xf0BEbC0708b758ebfc329833a6063cC2195Fc725), // soul address
                deployParams.protocolOwner,
                true
            );
        } else if (block.chainid == DeploySetting.LINEA_GOERLI) {
            LibDeploy.deployFactory(
                vm,
                deployParams.deployerContract,
                deployParams.entryPoint,
                address(0xf0BEbC0708b758ebfc329833a6063cC2195Fc725), // soul address
                deployParams.protocolOwner,
                true
            );
        } else if (block.chainid == DeploySetting.SCROLL_SEPOLIA) {
            LibDeploy.deployFactory(
                vm,
                deployParams.deployerContract,
                deployParams.entryPoint,
                address(0xf0BEbC0708b758ebfc329833a6063cC2195Fc725), // soul address
                deployParams.protocolOwner,
                true
            );
        }

        vm.stopBroadcast();
    }
}
