// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import "../src/periphery/TestSwap.sol";
import "../src/periphery/TestTokenA.sol";
import "../src/periphery/TestTokenB.sol";

contract DeployTestSwap is Script {
    function run() external {
        vm.startBroadcast();

        address tokenAAddress = address(new TestTokenA());
        address tokenBAddress = address(new TestTokenB());
        address swapAddress = address(new TestSwap());
        console.log("tokenAAddress: %s", tokenAAddress);
        console.log("tokenBAddress: %s", tokenBAddress);
        console.log("swapAddress: %s", swapAddress);

        vm.stopBroadcast();
    }
}
