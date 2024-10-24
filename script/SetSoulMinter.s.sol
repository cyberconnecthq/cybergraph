// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract SetSoulMinter is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (
            block.chainid == DeploySetting.CYBER_TESTNET ||
            block.chainid == DeploySetting.CYBER ||
            block.chainid == DeploySetting.OPTIMISM
        ) {
            LibDeploy.setSoulMinter(
                vm,
                address(0x14A725839184F879f3C09cE3d707e5a3E4C5869d), // soul
                address(0xf320Ebd311C2650f574f98f3318A1CD204d873ee), // factory
                true
            );
        }
        vm.stopBroadcast();
    }
}
