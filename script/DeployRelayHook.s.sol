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
                0x9071ff33aEF10A1C20F206AD654bB8a5BEe976aa,
                0x4bd1246F9814a84E79f92b5Fe7083aC3994Fc205,
                deployParams.backendSigner,
                0x7169D38820dfd117C3FA1f22a697dBA58d90BA06
            );
        } else if (block.chainid == DeploySetting.BNB) {
            LibDeploy.deployNFTRelayHook(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                0x9071ff33aEF10A1C20F206AD654bB8a5BEe976aa,
                0x4bd1246F9814a84E79f92b5Fe7083aC3994Fc205,
                0x16Daa4649035D5a0A7E76361caf75a46F1A1062a,
                0x21FD16cD0eF24A49D28429921e335bb0C1bfAdB3
            );
        }

        vm.stopBroadcast();
    }
}
