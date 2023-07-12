// SPDX-License-Identifier: GPL-3.0-or-later
import { ERC721 } from "../../src/dependencies/solmate/ERC721.sol";
import { ERC1155 } from "solmate/src/tokens/ERC1155.sol";

import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";
import { MockMiddleware } from "../utils/MockMiddleware.sol";

import { Soul } from "../../src/core/Soul.sol";
import { Essence } from "../../src/core/Essence.sol";
import { Content } from "../../src/core/Content.sol";
import { W3st } from "../../src/core/W3st.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { MiddlewareManager } from "../../src/core/MiddlewareManager.sol";
import { CyberAccountFactory } from "../../src/factory/CyberAccountFactory.sol";

import "forge-std/console.sol";
import "kernel/src/Kernel.sol";

pragma solidity 0.8.14;

contract IntegrationFactoryTest is TestIntegrationBase {
    function setUp() public {
        _setUp();
    }

    function test_CreateAccount() public {
        // address owner = address(0xb0b);
        // address val = address(0x180D6465F921C7E0DEA0040107D342c87455fFF5);
        // IKernelValidator iev = IKernelValidator(val);
        // CyberAccountFactory(addrs.cyberFactory).createAccount(
        //     iev,
        //     abi.encodePacked(owner),
        //     1
        // );
    }
}
