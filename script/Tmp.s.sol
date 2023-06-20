// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { CyberEngine } from "../src/core/CyberEngine.sol";
import { CyberAccount } from "../src/core/CyberAccount.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";
import { CyberAccountFactory } from "../src/factory/CyberAccountFactory.sol";
import { Soul } from "../src/core/Soul.sol";
import { W3st } from "../src/core/W3st.sol";

contract TempScript is Script {
    function run() external {
        vm.startBroadcast();
        CyberAccountFactory factory = CyberAccountFactory(
            address(0xec73A6E5629AAAD9D5fE6170d250A618fe0B6E05)
        );
        // CyberAccount myAccount = factory.createAccount(msg.sender, 1);
        // console.log(address(myAccount));

        CyberAccount myAccount = CyberAccount(
            payable(factory.getAddress(msg.sender, 0))
        );
        // Soul(0x77350F03693dA1DE12003b8A6a2AfC004788542a).createSoul(
        //     address(myAccount),
        //     true
        // );
        // myAccount.execute(
        //     address(0x0FD51A4bf0f885496a41db946Bd9a5cCCd69b771),
        //     0,
        //     abi.encodeWithSelector(
        //         CyberEngine.issueW3st.selector,
        //         DataTypes.IssueW3stParams(
        //             address(myAccount),
        //             "https://ipfs.io/myw3sttokenuri",
        //             address(0),
        //             true
        //         ),
        //         new bytes(0)
        //     )
        // );
        // myAccount.execute(
        //     address(0x0FD51A4bf0f885496a41db946Bd9a5cCCd69b771),
        //     0,
        //     abi.encodeWithSelector(
        //         CyberEngine.setOperatorApproval.selector,
        //         msg.sender,
        //         true
        //     )
        // );
        // CyberEngine cyberEngine = CyberEngine(
        //     address(0x0FD51A4bf0f885496a41db946Bd9a5cCCd69b771)
        // );
        // cyberEngine.issueW3st(
        //     DataTypes.IssueW3stParams(
        //         address(myAccount),
        //         "https://ipfs.io/myw3sttokenuri",
        //         address(0),
        //         true
        //     ),
        //     new bytes(0)
        // );
        // cyberEngine.collect(
        //     DataTypes.CollectParams(
        //         address(myAccount),
        //         0,
        //         5,
        //         DataTypes.Category.W3ST
        //     ),
        //     new bytes(0)
        // );
        W3st(0x1D9C591898B187e6c27AC6aF0BF2cB668413327B).safeTransferFrom(
            msg.sender,
            0x396428f6aD7E1DFb936ff88471569d115aBC1435,
            0,
            3,
            new bytes(0)
        );
        vm.stopBroadcast();
    }
}
