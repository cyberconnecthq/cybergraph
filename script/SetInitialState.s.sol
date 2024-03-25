// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract SetInitialState is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (
            block.chainid == DeploySetting.POLYGON ||
            block.chainid == DeploySetting.LINEA ||
            block.chainid == DeploySetting.BNB ||
            block.chainid == DeploySetting.OPTIMISM ||
            block.chainid == DeploySetting.BASE ||
            block.chainid == DeploySetting.BASE_GOERLI ||
            block.chainid == DeploySetting.ARBITRUM ||
            block.chainid == DeploySetting.OPBNB ||
            block.chainid == DeploySetting.LINEA_GOERLI ||
            block.chainid == DeploySetting.BNBT ||
            block.chainid == DeploySetting.OP_GOERLI ||
            block.chainid == DeploySetting.ARBITRUM_GOERLI ||
            block.chainid == DeploySetting.OPBNB_TESTNET ||
            block.chainid == DeploySetting.SCROLL_SEPOLIA ||
            block.chainid == DeploySetting.MUMBAI ||
            block.chainid == DeploySetting.SCROLL ||
            block.chainid == DeploySetting.ETH ||
            block.chainid == DeploySetting.SEPOLIA ||
            block.chainid == DeploySetting.MANTLE_TESTENT ||
            block.chainid == DeploySetting.MANTLE ||
            block.chainid == DeploySetting.BLAST_SEPOLIA ||
            block.chainid == DeploySetting.OP_SEPOLIA ||
            block.chainid == DeploySetting.BASE_SEPOLIA ||
            block.chainid == DeploySetting.BLAST ||
            block.chainid == DeploySetting.CYBER_TESTNET
        ) {
            LibDeploy.setInitialState(
                vm,
                deployParams.deployerContract,
                address(0x72c837fE8Ba6C7fD69cEF66B6E85c0D7eAbF1f9b), // mwManager
                address(0x414CB5822CA5141aeDaEa9D64A12f511071F7613), // permissionMw
                address(0x14A725839184F879f3C09cE3d707e5a3E4C5869d), // soul
                address(0xAEE9762ce625E0a8F7b184670fB57C37BFE1d0f1), // factory
                address(0x672Cf56a66b6f6A0A97F188abE57249fB7EeF909), // cyberpaymaster
                deployParams.backendSigner
            );
        }
        vm.stopBroadcast();
    }
}
