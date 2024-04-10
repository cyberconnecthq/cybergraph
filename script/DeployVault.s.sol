// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployVault is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();
        if (
            block.chainid == DeploySetting.OPTIMISM ||
            block.chainid == DeploySetting.OP_GOERLI ||
            block.chainid == DeploySetting.OP_SEPOLIA
        ) {
            // LibDeploy.deployVault(
            //     vm,
            //     deployParams.deployerContract,
            //     deployParams.protocolOwner,
            //     deployParams.treasuryReceiver,
            //     deployParams.backendSigner
            // );
        } else if (block.chainid == DeploySetting.SEPOLIA) {
            address[] memory wl = new address[](2);
            wl[0] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
            wl[1] = address(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238);
            bool[] memory wlStatus = new bool[](2);
            wlStatus[0] = true;
            wlStatus[1] = true;

            LibDeploy.deployVault(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD,
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                0x7169D38820dfd117C3FA1f22a697dBA58d90BA06,
                wl,
                wlStatus
            );
        } else if (block.chainid == DeploySetting.ETH) {
            address[] memory wl = new address[](2);
            wl[0] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
            wl[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
            bool[] memory wlStatus = new bool[](2);
            wlStatus[0] = true;
            wlStatus[1] = true;

            LibDeploy.deployVault(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD,
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                0xdAC17F958D2ee523a2206206994597C13D831ec7,
                wl,
                wlStatus
            );
        } else if (block.chainid == DeploySetting.BASE) {
            address[] memory wl = new address[](1);
            wl[0] = address(0x4200000000000000000000000000000000000006);
            bool[] memory wlStatus = new bool[](1);
            wlStatus[0] = true;

            LibDeploy.deployVault(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                0x198EF79F1F515F02dFE9e3115eD9fC07183f02fC,
                0x4200000000000000000000000000000000000006,
                0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
                wl,
                wlStatus
            );
        } else if (block.chainid == DeploySetting.ARBITRUM) {
            address[] memory wl = new address[](2);
            wl[0] = address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
            wl[1] = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
            bool[] memory wlStatus = new bool[](2);
            wlStatus[0] = true;
            wlStatus[1] = true;

            LibDeploy.deployVault(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD,
                0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
                0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9,
                wl,
                wlStatus
            );
        } else if (block.chainid == DeploySetting.BNB) {
            address[] memory wl = new address[](2);
            wl[0] = address(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
            wl[1] = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
            bool[] memory wlStatus = new bool[](2);
            wlStatus[0] = true;
            wlStatus[1] = true;

            LibDeploy.deployVault(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                0x4Dae2f939ACf50408e13d58534Ff8c2776d45265,
                0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,
                0x55d398326f99059fF775485246999027B3197955,
                wl,
                wlStatus
            );
        } else if (block.chainid == DeploySetting.POLYGON) {
            address[] memory wl = new address[](2);
            wl[0] = address(0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359);
            wl[1] = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
            bool[] memory wlStatus = new bool[](2);
            wlStatus[0] = true;
            wlStatus[1] = true;

            LibDeploy.deployVault(
                vm,
                deployParams.deployerContract,
                deployParams.protocolOwner,
                deployParams.protocolOwner,
                deployParams.backendSigner,
                0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD,
                0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
                0xc2132D05D31c914a87C6611C10748AEb04B58e8F,
                wl,
                wlStatus
            );
        }
        vm.stopBroadcast();
    }
}

contract UpgradeVault is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();
        if (block.chainid == DeploySetting.OP_SEPOLIA) {
            LibDeploy.upgradeVault(
                vm,
                deployParams.deployerContract,
                0x5254857780901d6cc80E42946a7D101FE8667EA8
            );
        } else if (block.chainid == DeploySetting.OPTIMISM) {
            LibDeploy.upgradeVault(
                vm,
                deployParams.deployerContract,
                0x5b3A81f9B29E51518316B4E2B8FD5986a3785CA4
            );
        }
        vm.stopBroadcast();
    }
}
