// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { LibDeploy } from "../../script/libraries/LibDeploy.sol";

abstract contract TestIntegrationBase is Test {
    address internal constant protocolOwner = address(0x1);
    address internal constant treasuryReceiver = address(0x2);

    LibDeploy.ContractAddresses addrs;

    function _setUp() internal {
        addrs = LibDeploy.deployInTest(vm, protocolOwner, treasuryReceiver);
    }
}
