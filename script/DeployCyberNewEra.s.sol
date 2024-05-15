// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployCyberNewEra is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.CYBER_TESTNET) {
            LibDeploy.deployCyberNewEra(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                "https://metadata.stg.cyberconnect.dev/new_era/1.json"
            );
        } else if (block.chainid == DeploySetting.CYBER) {
            LibDeploy.deployCyberNewEra(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                "https://metadata.cyberconnect.dev/new_era/1.json"
            );
        } else {
            revert("UNSUPPORTED_CHAIN");
        }
        vm.stopBroadcast();
    }
}
