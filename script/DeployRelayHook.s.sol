// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployNFTRelayHook is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.OP_SEPOLIA) {
            LibDeploy.deployNFTRelayHook(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                0x9071ff33aEF10A1C20F206AD654bB8a5BEe976aa,
                0x60A1b9c6900C6cEF0e08B939cc00635Ad7DF02a1,
                deployParams.backendSigner,
                0xB21C65A0903B8c4da0F2Bc59104A5376157a44Ef
            );
        } else if (block.chainid == DeploySetting.BNB) {
            LibDeploy.deployNFTRelayHook(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                0x9071ff33aEF10A1C20F206AD654bB8a5BEe976aa,
                0x60A1b9c6900C6cEF0e08B939cc00635Ad7DF02a1,
                0x16Daa4649035D5a0A7E76361caf75a46F1A1062a,
                0x21FD16cD0eF24A49D28429921e335bb0C1bfAdB3
            );
        }

        vm.stopBroadcast();
    }
}

contract DeployCyberIDRelayHook is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.OP_SEPOLIA) {
            LibDeploy.deployCyberIdRelayHook(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                0x9071ff33aEF10A1C20F206AD654bB8a5BEe976aa,
                0x58688732998f6c9f7Bde811C6576AD471C373061,
                deployParams.backendSigner,
                0x61Ec26aA57019C486B10502285c5A3D4A4750AD7
            );
        }

        vm.stopBroadcast();
    }
}
