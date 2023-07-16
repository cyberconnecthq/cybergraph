// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract SetInitialState is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.POLYGON) {
            LibDeploy.setInitialState(
                vm,
                deployParams.deployerContract,
                address(0x72c837fE8Ba6C7fD69cEF66B6E85c0D7eAbF1f9b), // mwManager
                address(0x414CB5822CA5141aeDaEa9D64A12f511071F7613), // permissionMw
                address(0x14A725839184F879f3C09cE3d707e5a3E4C5869d), // soul
                address(0xAEE9762ce625E0a8F7b184670fB57C37BFE1d0f1), // factory
                address(0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82) // backendSigner
            );
        }
        vm.stopBroadcast();
    }
}
