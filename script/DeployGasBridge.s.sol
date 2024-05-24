// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployGasBridge is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (
            block.chainid == DeploySetting.SEPOLIA ||
            block.chainid == DeploySetting.OPTIMISM ||
            block.chainid == DeploySetting.ARBITRUM ||
            block.chainid == DeploySetting.BASE ||
            block.chainid == DeploySetting.BLAST ||
            block.chainid == DeploySetting.ETH
        ) {
            LibDeploy.deployGasBridge(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner
            );
        } else {
            revert("UNSUPPORTED_CHAIN");
        }
        vm.stopBroadcast();
    }
}
