// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { DataTypes } from "../src/libraries/DataTypes.sol";

import { CyberEngine } from "../src/core/CyberEngine.sol";
import { MockEngineV2 } from "./utils/MockEngineV2.sol";

contract CyberEngineUpgradeTest is Test {
    CyberEngine internal engine;
    ERC1967Proxy internal proxy;

    address constant alice = address(0xA11CE);
    address constant admin = address(0xB0B);

    function setUp() public {
        CyberEngine engineImpl = new CyberEngine();
        bytes memory data = abi.encodeWithSelector(
            CyberEngine.initialize.selector,
            DataTypes.InitParams(
                address(0x1),
                address(0x1),
                address(0x1),
                address(0x1),
                address(0x1),
                address(0x1),
                admin
            )
        );
        ERC1967Proxy engineProxy = new ERC1967Proxy(address(engineImpl), data);
        engine = CyberEngine(address(engineProxy));
    }

    function testCannotUpgradeToAndCallAsNonAdmin() public {
        uint256 oldVersion = CyberEngine(address(engine)).version();
        MockEngineV2 implV2 = new MockEngineV2();

        vm.prank(alice);
        vm.expectRevert("UNAUTHORIZED");
        CyberEngine(address(engine)).upgradeToAndCall(
            address(implV2),
            abi.encodeWithSelector(MockEngineV2.version.selector)
        );
        assertEq(CyberEngine(address(engine)).version(), oldVersion);
    }

    function testCannotUpgradeAsNonAdmin() public {
        uint256 oldVersion = CyberEngine(address(engine)).version();
        MockEngineV2 implV2 = new MockEngineV2();

        vm.prank(alice);
        vm.expectRevert("UNAUTHORIZED");
        CyberEngine(address(engine)).upgradeTo(address(implV2));
        assertEq(CyberEngine(address(engine)).version(), oldVersion);
    }

    function testUpgrade() public {
        assertEq(CyberEngine(address(engine)).version(), 1);

        MockEngineV2 implV2 = new MockEngineV2();
        vm.prank(admin);

        CyberEngine(address(engine)).upgradeTo(address(implV2));
        assertEq(CyberEngine(address(engine)).version(), 2);
    }

    function testUpgradeToAndCall() public {
        MockEngineV2 implV2 = new MockEngineV2();

        vm.prank(admin);

        CyberEngine(address(engine)).upgradeToAndCall(
            address(implV2),
            abi.encodeWithSelector(MockEngineV2.version.selector)
        );
        assertEq(CyberEngine(address(engine)).version(), 2);
    }
}
