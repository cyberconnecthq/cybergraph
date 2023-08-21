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
        } else if (block.chainid == DeploySetting.BNBT) {
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
        } else if (block.chainid == DeploySetting.ARBITRUM_GOERLI) {
            require(
                msg.sender == 0x526010620cAB87A4afD0599914Bc57aac095Dd34,
                "address must be deployer"
            );
        } else if (block.chainid == DeploySetting.SCROLL_ALPHA) {
            require(
                msg.sender == 0x526010620cAB87A4afD0599914Bc57aac095Dd34,
                "address must be deployer"
            );
        } else if (block.chainid == DeploySetting.POLYGON) {
            require(
                msg.sender == 0x0e0bE581B17684f849AF6964D731FCe0F7d366BD,
                "address must be deployer"
            );
        } else if (block.chainid == DeploySetting.OPTIMISM) {
            require(
                msg.sender == 0x0e0bE581B17684f849AF6964D731FCe0F7d366BD,
                "address must be deployer"
            );
        } else if (block.chainid == DeploySetting.ARBITRUM) {
            require(
                msg.sender == 0x0e0bE581B17684f849AF6964D731FCe0F7d366BD,
                "address must be deployer"
            );
        } else if (block.chainid == DeploySetting.LINEA) {
            require(
                msg.sender == 0x0e0bE581B17684f849AF6964D731FCe0F7d366BD,
                "address must be deployer"
            );
        } else if (block.chainid == DeploySetting.BNB) {
            require(
                msg.sender == 0x0e0bE581B17684f849AF6964D731FCe0F7d366BD,
                "address must be deployer"
            );
        } else if (block.chainid == DeploySetting.ETH) {
            require(
                msg.sender == 0x0e0bE581B17684f849AF6964D731FCe0F7d366BD,
                "address must be deployer"
            );
        } else if (block.chainid == DeploySetting.NOVA) {
            require(
                msg.sender == 0x0e0bE581B17684f849AF6964D731FCe0F7d366BD,
                "address must be deployer"
            );
        } else if (block.chainid == DeploySetting.BASE) {
            require(
                msg.sender == 0x0e0bE581B17684f849AF6964D731FCe0F7d366BD,
                "address must be deployer"
            );
        } else {
            revert("PARAMS_NOT_SET");
        }

        vm.startBroadcast();
        new Create2Deployer();
        vm.stopBroadcast();
    }
}
