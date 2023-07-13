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
            0xeCB13962De4d484d988ad5927e92168bed1ac3ce
        );
        console.log(address(fac.kernelTemplate()));

        console.log(address(fac.nextTemplate()));
        console.log(
            address(
                fac.getAccountAddress(
                    IKernelValidator(
                        0xfd06500DE1A5D49B64A416eeDc9451218f8ab78e
                    ),
                    hex"2E0446079705B6Bacc4730fB3EDA5DA68aE5Fe4D",
                    0
                )
            )
        );

        fac.createAccount(
            IKernelValidator(0xfd06500DE1A5D49B64A416eeDc9451218f8ab78e),
            hex"2E0446079705B6Bacc4730fB3EDA5DA68aE5Fe4D",
            0
        );

        // console.logBytes(type(EIP1967Proxy).creationCode);

        vm.stopBroadcast();
    }
}
