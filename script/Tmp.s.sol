// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { CyberEngine } from "../src/core/CyberEngine.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";
import { CyberAccountFactory } from "../src/factory/CyberAccountFactory.sol";
import { Soul } from "../src/core/Soul.sol";
import { W3st } from "../src/core/W3st.sol";
import { EIP1967Proxy } from "kernel/src/factory/EIP1967Proxy.sol";
import { TempKernel } from "kernel/src/factory/TempKernel.sol";
import { ECDSAValidator } from "kernel/src/validator/ECDSAValidator.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { UserOperation } from "account-abstraction/interfaces/UserOperation.sol";
import "kernel/src/Kernel.sol";

import "forge-std/console.sol";

contract TempScript is Script {
    function run() external {
        vm.startBroadcast();

        CyberAccountFactory fac = CyberAccountFactory(
            0x70Efb7410922159Dd482CD848fB4a7e8c266F95c
        );
        console.log(address(fac.kernelTemplate()));
        console.log(address(fac.nextTemplate()));

        // console.log(
        //     fac.getAccountAddress(
        //         IKernelValidator(0x415F0433b90215817a070511083C40aE3876EDE8),
        //         hex"2E0446079705B6Bacc4730fB3EDA5DA68aE5Fe4D",
        //         uint256(0)
        //     )
        // );
        // IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789).StakeInfo(
        //     0x870fe151D548A1c527C3804866FaB30ABf28ED17
        // );

        vm.stopBroadcast();
    }
}
