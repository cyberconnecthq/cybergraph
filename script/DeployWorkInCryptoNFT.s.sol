// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployWorkInCryptoNFT is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        string memory name = "WorkInCryptoNFT";
        string memory symbol = "WICNFT";
        string memory uri = "https://metadata.cyberconnect.dev/workincrypto/";
        if (block.chainid == DeploySetting.OP_SEPOLIA) {
            uri = "https://metadata.stg.cyberconnect.dev/workincrypto/";
        }
        if (
            block.chainid == DeploySetting.OPTIMISM ||
            block.chainid == DeploySetting.OP_SEPOLIA
        ) {
            LibDeploy.deployWorkInCryptoNFT(
                vm,
                deployParams.deployerContract,
                name,
                symbol,
                uri,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                true
            );
        }
        vm.stopBroadcast();
    }
}
