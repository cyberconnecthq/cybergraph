// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { CyberStakingPool } from "../src/periphery/CyberStakingPool.sol";

contract DeployStakingPool is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.SEPOLIA) {
            LibDeploy.deployStakingPool(
                vm,
                deployParams.deployerContract,
                0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9,
                deployParams.protocolOwner
            );
        } else if (block.chainid == DeploySetting.ETH) {
            LibDeploy.deployStakingPool(
                vm,
                deployParams.deployerContract,
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                deployParams.protocolSafeV2
            );
        }
        vm.stopBroadcast();
    }
}

contract SetStakingPool is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.SEPOLIA) {
            CyberStakingPool pool = CyberStakingPool(
                payable(0x76f830D6a7021d834ad41683DaDEfe362C23c931)
            );
            pool.grantRole(
                keccak256(bytes("OPERATOR_ROLE")),
                deployParams.protocolOwner
            );
            pool.setAssetWhitelist(
                0xF616904ac19f5bE8206A923E92bFf8953a16c7Fc,
                true
            );
        } else if (block.chainid == DeploySetting.ETH) {}
        vm.stopBroadcast();
    }
}
