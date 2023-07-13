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
            0x1a2F4f79A7a4616c0C59f489c9984dB01ccbbE89
        );
        console.log(address(fac.kernelTemplate()));

        console.log(address(fac.nextTemplate()));
        console.log(
            address(
                fac.getAccountAddress(
                    IKernelValidator(
                        0xe573cb631588541841D4265C91fEd90498B485BA
                    ),
                    hex"2E0446079705B6Bacc4730fB3EDA5DA68aE5Fe4D",
                    0
                )
            )
        );

        // console.logBytes(type(EIP1967Proxy).creationCode);

        // Soul(0xB942509713BDc1418FE4e8E8d59030C95b40DCAF).setMinter(
        //     0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F,
        //     true
        // );

        vm.stopBroadcast();
    }
}
