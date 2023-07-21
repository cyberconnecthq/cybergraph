// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract ChangeOwner is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.POLYGON) {
            LibDeploy.changeOwnership(
                vm,
                address(0xCd78e2AB0F5363A5c3835C0423fa4055baCf91D6), // timelock
                address(0xcd97405Fb58e94954E825E46dB192b916A45d412) // token receiver
            );
        } else if (block.chainid == DeploySetting.LINEA) {
            LibDeploy.changeOwnership(
                vm,
                address(0x3c84a5d37aF5b8Cc435D9c8C1994deBa40fC9c19), // timelock
                address(0xcd97405Fb58e94954E825E46dB192b916A45d412) // token receiver
            );
        } else if (block.chainid == DeploySetting.BNB) {
            LibDeploy.changeOwnership(
                vm,
                address(0x3c84a5d37aF5b8Cc435D9c8C1994deBa40fC9c19), // timelock
                address(0xcd97405Fb58e94954E825E46dB192b916A45d412) // token receiver
            );
        }
        vm.stopBroadcast();
    }
}
