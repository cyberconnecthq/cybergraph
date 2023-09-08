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
            block.chainid == DeploySetting.MUMBAI ||
            block.chainid == DeploySetting.BASE_GOERLI ||
            block.chainid == DeploySetting.OP_GOERLI
        ) {
            // LibDeploy.deployPermissionMw(
            //     vm,
            //     deployParams.deployerContract,
            //     address(0x72cA12E2aae0C1c12D9796D9974a5F1204cf51f3), // engine
            //     address(0x2e0fa762fb63A2df1Ed76f20E776E291F777FA6F) // mwManager
            // );
            LibDeploy.deployLimitedOnlyOnceMw(
                vm,
                deployParams.deployerContract,
                address(0x72cA12E2aae0C1c12D9796D9974a5F1204cf51f3), // engine
                address(0x2e0fa762fb63A2df1Ed76f20E776E291F777FA6F) // mwManager
            );
        }
        vm.stopBroadcast();
    }
}
