// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployMw is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (
            block.chainid == DeploySetting.OPTIMISM ||
            block.chainid == DeploySetting.OP_GOERLI ||
            block.chainid == DeploySetting.OP_SEPOLIA
        ) {
            LibDeploy.deployLimitedOnlyOnceMw(
                vm,
                deployParams.deployerContract,
                address(0x4Bc54260EC3617b3F73fdb1fA22417ED109f372C), // engine
                address(0x72c837fE8Ba6C7fD69cEF66B6E85c0D7eAbF1f9b) // mwManager
            );
        }
        vm.stopBroadcast();
    }
}
