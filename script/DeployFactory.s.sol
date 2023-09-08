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
            block.chainid == DeploySetting.BASE_GOERLI ||
            block.chainid == DeploySetting.ARBITRUM_GOERLI ||
            block.chainid == DeploySetting.LINEA_GOERLI ||
            block.chainid == DeploySetting.OP_GOERLI ||
            block.chainid == DeploySetting.OPBNB_TESTNET
        ) {
            // LibDeploy.deployFactory(
            //     vm,
            //     deployParams.deployerContract,
            //     deployParams.entryPoint,
            //     address(0xf0BEbC0708b758ebfc329833a6063cC2195Fc725), // soul address
            //     deployParams.protocolOwner,
            //     true
            // );
            LibDeploy.deployFactoryV2(
                vm,
                deployParams.deployerContract,
                address(0x70Efb7410922159Dd482CD848fB4a7e8c266F95c), // v1 factory
                deployParams.entryPoint,
                deployParams.protocolOwner,
                true
            );
        } else {
            revert("NOT_SUPPORTED");
        }

        vm.stopBroadcast();
    }
}
