// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployCyberRelayer is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (
            block.chainid == DeploySetting.CYBER_TESTNET ||
            block.chainid == DeploySetting.CYBER
        ) {
            LibDeploy.deployCyberRelayer(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.backendSigner
            );
        } else {
            revert("UNSUPPORTED_CHAIN");
        }
        vm.stopBroadcast();
    }
}
