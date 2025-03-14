// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployAll is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (
            block.chainid == DeploySetting.MUMBAI ||
            block.chainid == DeploySetting.BASE_GOERLI ||
            block.chainid == DeploySetting.POLYGON ||
            block.chainid == DeploySetting.LINEA ||
            block.chainid == DeploySetting.LINEA_GOERLI ||
            block.chainid == DeploySetting.BNBT ||
            block.chainid == DeploySetting.BNB ||
            block.chainid == DeploySetting.OPTIMISM ||
            block.chainid == DeploySetting.OP_GOERLI ||
            block.chainid == DeploySetting.OP_SEPOLIA ||
            block.chainid == DeploySetting.BASE ||
            block.chainid == DeploySetting.BASE_SEPOLIA ||
            block.chainid == DeploySetting.ARBITRUM ||
            block.chainid == DeploySetting.ARBITRUM_GOERLI ||
            block.chainid == DeploySetting.OPBNB_TESTNET ||
            block.chainid == DeploySetting.OPBNB ||
            block.chainid == DeploySetting.SCROLL_SEPOLIA ||
            block.chainid == DeploySetting.SCROLL ||
            block.chainid == DeploySetting.ETH ||
            block.chainid == DeploySetting.SEPOLIA ||
            block.chainid == DeploySetting.MANTLE_TESTENT ||
            block.chainid == DeploySetting.MANTLE ||
            block.chainid == DeploySetting.BLAST_SEPOLIA ||
            block.chainid == DeploySetting.BLAST ||
            block.chainid == DeploySetting.CYBER_TESTNET ||
            block.chainid == DeploySetting.AMOY ||
            block.chainid == DeploySetting.IMX_TESTNET ||
            block.chainid == DeploySetting.CYBER
        ) {
            LibDeploy.deployAll(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.treasuryReceiver,
                deployParams.protocolOwner,
                deployParams.entryPoint,
                deployParams.backendSigner,
                true
            );
        } else if (block.chainid == DeploySetting.APE_TESTNET) {
            LibDeploy.simpleDeployAll(
                vm,
                deployParams.deployerContract,
                deployParams.backendSigner
            );
        }
        vm.stopBroadcast();
    }
}
