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

        console.log(
            address(
                CyberAccountFactory(0x5684d19825cf5900345e4dfF2d8941c2092d2d99)
                    .kernelTemplate()
            )
        );

        console.log(
            address(
                CyberAccountFactory(0x5684d19825cf5900345e4dfF2d8941c2092d2d99)
                    .nextTemplate()
            )
        );
        // console.log(
        //     address(
        //         CyberAccountFactory(0x5684d19825cf5900345e4dfF2d8941c2092d2d99)
        //             .getAccountAddress(
        //                 IKernelValidator(
        //                     0x180D6465F921C7E0DEA0040107D342c87455fFF5
        //                 ),
        //                 hex"4603a49D74F15a02994d80F3B3913A17Bf5eFCaf",
        //                 0
        //             )
        //     )
        // );

        // console.logBytes(type(EIP1967Proxy).creationCode);

        // Soul(0x950453Fdc75510e250806769A342F3129E3C3Fad).createSoul(
        //     0xcA160793501321eb33Fca67ec67aE59a27a9BE21,
        //     true
        // );

        Soul(0x950453Fdc75510e250806769A342F3129E3C3Fad).setMinter(
            0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F,
            true
        );

        vm.stopBroadcast();
    }
}
