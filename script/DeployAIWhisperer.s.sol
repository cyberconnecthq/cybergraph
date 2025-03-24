// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

import { AIWhispererNFT } from "../src/periphery/AIWhispererNFT.sol";

contract DeployAIWhisperer is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.CYBER) {
            AIWhispererNFT nft = new AIWhispererNFT(
                "https://metadata.cyberconnect.dev/nfts/aiwhisperer/",
                0x0e3Ba6BE9b3AAf4c6dE0C9AEe2b2c565E29437Ae
            );
            LibDeploy._write(vm, "AIWhispererNFT", address(nft));
        } else if (block.chainid == DeploySetting.CYBER_TESTNET) {
            AIWhispererNFT nft = new AIWhispererNFT(
                "https://metadata.stg.cyberconnect.dev/nfts/aiwhisperer/",
                0x0e3Ba6BE9b3AAf4c6dE0C9AEe2b2c565E29437Ae
            );
            LibDeploy._write(vm, "AIWhispererNFT", address(nft));
        }
        vm.stopBroadcast();
    }
}
