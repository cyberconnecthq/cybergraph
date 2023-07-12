// SPDX-License-Identifier: GPL-3.0-or-later
import "kernel/src/Kernel.sol";
import { ERC721 } from "../../src/dependencies/solmate/ERC721.sol";
import { ECDSAValidator } from "kernel/src/validator/ECDSAValidator.sol";

import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";
import { Soul } from "../../src/core/Soul.sol";
import { CyberAccountFactory } from "../../src/factory/CyberAccountFactory.sol";

pragma solidity 0.8.14;

contract IntegrationFactoryTest is TestIntegrationBase {
    ECDSAValidator validator;

    function setUp() public {
        _setUp();
        validator = new ECDSAValidator();
    }

    function test_CreateAccount() public {
        address owner = address(0xb0b);
        IKernelValidator iev = IKernelValidator(address(validator));
        address newAcc = address(
            CyberAccountFactory(addrs.cyberFactory).createAccount(
                iev,
                abi.encodePacked(owner),
                0
            )
        );
        require(ERC721(addrs.soul).balanceOf(newAcc) == 1, "NOT_OWNER");
    }
}
