// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import { Create2Deployer } from "../src/deployer/Create2Deployer.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";

contract DeployerCreate2Deployer is Script, DeploySetting {
    function run() external {
        uint256 nonce = vm.getNonce(msg.sender);
        require(nonce == 0, "nonce must be 0");

        if (block.chainid == DeploySetting.MUMBAI) {
            require(
                msg.sender == 0x526010620cAB87A4afD0599914Bc57aac095Dd34,
                "address must be deployer"
            );
        } else if (block.chainid == DeploySetting.OP_GOERLI) {
            require(
                msg.sender == 0x526010620cAB87A4afD0599914Bc57aac095Dd34,
                "address must be deployer"
            );
        } else if (block.chainid == DeploySetting.BASE_GOERLI) {
            require(
                msg.sender == 0x526010620cAB87A4afD0599914Bc57aac095Dd34,
                "address must be deployer"
            );
        } else if (block.chainid == DeploySetting.LINEA_GOERLI) {
            require(
                msg.sender == 0x526010620cAB87A4afD0599914Bc57aac095Dd34,
                "address must be deployer"
            );
        } else if (block.chainid == DeploySetting.SCROLL_ALPHA) {
            require(
                msg.sender == 0x526010620cAB87A4afD0599914Bc57aac095Dd34,
                "address must be deployer"
            );
        } else {
            revert("PARAMS_NOT_SET");
1ba7 (zk rollup and factory test)
        }

        vm.startBroadcast();
        new Create2Deployer();
        vm.stopBroadcast();
    }
}
