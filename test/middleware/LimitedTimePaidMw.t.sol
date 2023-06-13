// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";
import { MockERC20 } from "../utils/MockERC20.sol";
import { Soul } from "../../src/core/Soul.sol";
import { LimitedTimePaidMw } from "../../src/middlewares/LimitedTimePaidMw.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { MiddlewareManager } from "../../src/core/MiddlewareManager.sol";
import { Treasury } from "../../src/middlewares/base/Treasury.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";

contract LimitedTimePaidMwTest is TestIntegrationBase {
    address public mw;
    address public mockToken;
    address public alice = address(0x1);

    string constant BOB_ISSUED_1_URL = "mf.com";

    function setUp() public {
        _setUp();
        Soul(addrs.soul).createSoul(alice, false);
        mw = address(
            new LimitedTimePaidMw(addrs.cyberTreasury, addrs.engine, addrs.soul)
        );
        mockToken = address(new MockERC20());
        vm.prank(protocolOwner);
        Treasury(addrs.cyberTreasury).allowCurrency(mockToken, true);
        vm.prank(protocolOwner);
        MiddlewareManager(addrs.manager).allowMw(address(mw), true);
    }

    function testSetMwData() public {
        vm.prank(alice);
        uint256 tokenId = CyberEngine(addrs.engine).publishContent(
            DataTypes.PublishContentParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(
                uint256(100),
                uint256(1 ether),
                alice,
                mockToken,
                uint256(1786564834),
                uint256(0),
                // 10%
                uint16(1000),
                false
            )
        );
        assertEq(tokenId, 0);
    }
}
