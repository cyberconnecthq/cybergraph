// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployNFTRelayHook is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.SEPOLIA) {
            LibDeploy.deployNFTRelayHook(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                0x9356b95392EEb834Ebff98BC0ccC1e2eD5867100,
                0x4bd1246F9814a84E79f92b5Fe7083aC3994Fc205,
                deployParams.backendSigner,
                0x7169D38820dfd117C3FA1f22a697dBA58d90BA06
            );
        }

        vm.stopBroadcast();
    }
}
