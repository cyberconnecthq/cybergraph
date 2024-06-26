// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployCyberNewEraGate is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (
            block.chainid == DeploySetting.SEPOLIA ||
            block.chainid == DeploySetting.ARBITRUM ||
            block.chainid == DeploySetting.BASE ||
            block.chainid == DeploySetting.BLAST ||
            block.chainid == DeploySetting.OPTIMISM ||
            block.chainid == DeploySetting.ETH
        ) {
            LibDeploy.deployCyberNewEraGate(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                0.0007560 ether
            );
        } else {
            revert("UNSUPPORTED_CHAIN");
        }
        vm.stopBroadcast();
    }
}
