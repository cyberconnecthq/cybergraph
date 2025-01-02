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
                deployParams.backendSigner
            );
        } else if (block.chainid == DeploySetting.BNB) {
            LibDeploy.deployNFTRelayHook(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                0x9071ff33aEF10A1C20F206AD654bB8a5BEe976aa,
                0x60A1b9c6900C6cEF0e08B939cc00635Ad7DF02a1,
                0x16Daa4649035D5a0A7E76361caf75a46F1A1062a
            );
        } else if (
            block.chainid == DeploySetting.OPTIMISM ||
            block.chainid == DeploySetting.ARBITRUM ||
            block.chainid == DeploySetting.ETH ||
            block.chainid == DeploySetting.BLAST ||
            block.chainid == DeploySetting.BASE
        ) {
            LibDeploy.deployNFTRelayHook(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                0x9071ff33aEF10A1C20F206AD654bB8a5BEe976aa,
                0x60A1b9c6900C6cEF0e08B939cc00635Ad7DF02a1,
                0x15d4fD9130E1304086F4419ACd8Bc513a3E7b279
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
        } else if (block.chainid == DeploySetting.ARBITRUM) {
            LibDeploy.deployCyberIdRelayHook(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                0x9071ff33aEF10A1C20F206AD654bB8a5BEe976aa,
                0xC137Be6B59E824672aaDa673e55Cf4D150669af8,
                0x164F005B8D305ec60e10A039C36D099A8895323C,
                0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
            );
        } else if (block.chainid == DeploySetting.OPTIMISM) {
            LibDeploy.deployCyberIdRelayHook(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                0x9071ff33aEF10A1C20F206AD654bB8a5BEe976aa,
                0xC137Be6B59E824672aaDa673e55Cf4D150669af8,
                0x164F005B8D305ec60e10A039C36D099A8895323C,
                0x13e3Ee699D1909E989722E753853AE30b17e08c5
            );
        } else if (block.chainid == DeploySetting.ETH) {
            LibDeploy.deployCyberIdRelayHook(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                0x9071ff33aEF10A1C20F206AD654bB8a5BEe976aa,
                0xC137Be6B59E824672aaDa673e55Cf4D150669af8,
                0x164F005B8D305ec60e10A039C36D099A8895323C,
                0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            );
        } else if (block.chainid == DeploySetting.BLAST) {
            LibDeploy.deployCyberIdRelayHook(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                0x9071ff33aEF10A1C20F206AD654bB8a5BEe976aa,
                0xC137Be6B59E824672aaDa673e55Cf4D150669af8,
                0x164F005B8D305ec60e10A039C36D099A8895323C,
                0x0af23B08bcd8AD35D1e8e8f2D2B779024Bd8D24A
            );
        } else if (block.chainid == DeploySetting.BASE) {
            LibDeploy.deployCyberIdRelayHook(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                0x9071ff33aEF10A1C20F206AD654bB8a5BEe976aa,
                0xC137Be6B59E824672aaDa673e55Cf4D150669af8,
                0x164F005B8D305ec60e10A039C36D099A8895323C,
                0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70
            );
        }

        vm.stopBroadcast();
    }
}

contract DeploySnakeRelayHook is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();
        if (block.chainid == DeploySetting.OP_SEPOLIA) {
            LibDeploy.deploySnakeRelayHook(
                vm,
                deployParams.deployerContract,
                0xB82681f70CBd189Ed61Aa751A7912CC54f757aE3,
                0x9071ff33aEF10A1C20F206AD654bB8a5BEe976aa
            );
        } else if (
            block.chainid == DeploySetting.OPTIMISM ||
            block.chainid == DeploySetting.ETH ||
            block.chainid == DeploySetting.BLAST ||
            block.chainid == DeploySetting.BASE ||
            block.chainid == DeploySetting.ARBITRUM
        ) {
            LibDeploy.deploySnakeRelayHook(
                vm,
                deployParams.deployerContract,
                0x4Ce41028c305208Ab87d5681836f9E373CF741A1,
                0x9071ff33aEF10A1C20F206AD654bB8a5BEe976aa
            );
        }

        vm.stopBroadcast();
    }
}
