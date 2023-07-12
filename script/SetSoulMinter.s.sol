// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract SetSoulMinter is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.MUMBAI) {
            LibDeploy.setSoulMinter(
                vm,
                address(0xf0BEbC0708b758ebfc329833a6063cC2195Fc725), // soul
                address(0x5755B524Cd9433677508a98507dA469B625D003b), // factory
                true
            );
        }
        vm.stopBroadcast();
    }
}
