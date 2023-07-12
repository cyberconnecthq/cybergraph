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
                CyberAccountFactory(0x2DAB5E3e3449b5CaDf5126154fAbFe6d1e0e8aaD)
                    .kernelTemplate()
            )
        );

        console.log(
            address(
                CyberAccountFactory(0x2DAB5E3e3449b5CaDf5126154fAbFe6d1e0e8aaD)
                    .nextTemplate()
            )
        );
        console.log(
            address(
                CyberAccountFactory(0x2DAB5E3e3449b5CaDf5126154fAbFe6d1e0e8aaD)
                    .getAccountAddress(
                        IKernelValidator(
                            0xf94E5a47150d20C4B804C30B6699d786549A5821
                        ),
                        hex"2E0446079705B6Bacc4730fB3EDA5DA68aE5Fe4D",
                        0
                    )
            )
        );

        // console.logBytes(type(EIP1967Proxy).creationCode);

        // Soul(0xf0BEbC0708b758ebfc329833a6063cC2195Fc725).setMinter(
        //     0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F,
        //     true
        // );

        vm.stopBroadcast();
    }
}
