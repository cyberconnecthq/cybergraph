// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import { Create2Deployer } from "../src/deployer/Create2Deployer.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";

contract DeployerCreate2Deployer is Script, DeploySetting {
    function run() external {
        uint256 nonce = vm.getNonce(msg.sender);
        require(nonce == 0, "nonce must be 0");

        if (
            block.chainid == DeploySetting.MUMBAI ||
            block.chainid == DeploySetting.OP_GOERLI ||
            block.chainid == DeploySetting.BASE_GOERLI ||
            block.chainid == DeploySetting.LINEA_GOERLI ||
            block.chainid == DeploySetting.ARBITRUM_GOERLI ||
            block.chainid == DeploySetting.SCROLL_SEPOLIA ||
            block.chainid == DeploySetting.BNBT ||
            block.chainid == DeploySetting.OPBNB_TESTNET ||
            block.chainid == DeploySetting.OPBNB ||
            block.chainid == DeploySetting.POLYGON ||
            block.chainid == DeploySetting.OPTIMISM ||
            block.chainid == DeploySetting.ARBITRUM ||
            block.chainid == DeploySetting.LINEA ||
            block.chainid == DeploySetting.BNB ||
            block.chainid == DeploySetting.ETH ||
            block.chainid == DeploySetting.NOVA ||
            block.chainid == DeploySetting.BASE ||
            block.chainid == DeploySetting.SCROLL ||
            block.chainid == DeploySetting.SEPOLIA ||
            block.chainid == DeploySetting.MANTLE_TESTENT ||
            block.chainid == DeploySetting.MANTLE ||
            block.chainid == DeploySetting.BLAST_SEPOLIA ||
            block.chainid == DeploySetting.OP_SEPOLIA ||
            block.chainid == DeploySetting.BASE_SEPOLIA
        ) {
            require(
                msg.sender == 0x0e0bE581B17684f849AF6964D731FCe0F7d366BD,
                "address must be deployer"
            );
        } else {
            revert("PARAMS_NOT_SET");
        }

        vm.startBroadcast();
        address deployer = address(new Create2Deployer());
        require(
            deployer == 0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f,
            "wrong address"
        );
        vm.stopBroadcast();
    }
}
