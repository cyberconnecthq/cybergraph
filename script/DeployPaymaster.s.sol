// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployPaymaster is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (
            block.chainid == DeploySetting.BASE_GOERLI ||
            block.chainid == DeploySetting.BASE ||
            block.chainid == DeploySetting.SEPOLIA ||
            block.chainid == DeploySetting.BNBT ||
            block.chainid == DeploySetting.MUMBAI ||
            block.chainid == DeploySetting.LINEA_GOERLI ||
            block.chainid == DeploySetting.OP_GOERLI ||
            block.chainid == DeploySetting.SCROLL_SEPOLIA ||
            block.chainid == DeploySetting.POLYGON ||
            block.chainid == DeploySetting.LINEA ||
            block.chainid == DeploySetting.OPTIMISM ||
            block.chainid == DeploySetting.ARBITRUM ||
            block.chainid == DeploySetting.OPBNB ||
            block.chainid == DeploySetting.SCROLL ||
            block.chainid == DeploySetting.ETH ||
            block.chainid == DeploySetting.BNB ||
            block.chainid == DeploySetting.MANTLE ||
            block.chainid == DeploySetting.BLAST_SEPOLIA ||
            block.chainid == DeploySetting.OP_SEPOLIA ||
            block.chainid == DeploySetting.BASE_SEPOLIA
        ) {
            LibDeploy.deployPaymaster(
                vm,
                deployParams.deployerContract,
                deployParams.entryPoint,
                deployParams.protocolOwner,
                deployParams.backendSigner
            );
        }
        vm.stopBroadcast();
    }
}
