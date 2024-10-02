// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployCyberProjectNFTV2 is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (
            block.chainid == DeploySetting.CYBER_TESTNET ||
            block.chainid == DeploySetting.CYBER
        ) {
            LibDeploy.deployCyberNFT(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner
            );
        }
        vm.stopBroadcast();
    }
}
