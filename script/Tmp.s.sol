// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { CyberEngine } from "../src/core/CyberEngine.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";
import { CyberAccountFactory } from "../src/factory/CyberAccountFactory.sol";
import { Soul } from "../src/core/Soul.sol";
import { W3st } from "../src/core/W3st.sol";
import { TokenReceiver } from "../src/periphery/TokenReceiver.sol";
import { EIP1967Proxy } from "kernel/src/factory/EIP1967Proxy.sol";
import { TempKernel } from "kernel/src/factory/TempKernel.sol";
import { ECDSAValidator } from "kernel/src/validator/ECDSAValidator.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { UserOperation } from "account-abstraction/interfaces/UserOperation.sol";
import { CyberPaymaster } from "../src/paymaster/CyberPaymaster.sol";
import "kernel/src/Kernel.sol";

import "forge-std/console.sol";

contract TempScript is Script {
    function run() external {
        vm.startBroadcast();
        vm.stopBroadcast();
    }
}
