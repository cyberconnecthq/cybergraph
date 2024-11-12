// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployNFTRelayHook is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (
            block.chainid == DeploySetting.OP_SEPOLIA ||
            block.chainid == DeploySetting.CYBER_TESTNET
        ) {
            LibDeploy.deployYumeRelayHook(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner
            );
        } else if (
            block.chainid == DeploySetting.CYBER ||
            block.chainid == DeploySetting.ARBITRUM ||
            block.chainid == DeploySetting.OPTIMISM ||
            block.chainid == DeploySetting.BLAST ||
            block.chainid == DeploySetting.BASE ||
            block.chainid == DeploySetting.ETH
        ) {
            LibDeploy.deployYumeRelayHook(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner
            );
        }

        vm.stopBroadcast();
    }
}
