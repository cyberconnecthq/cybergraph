// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { CyberRelayer } from "../src/periphery/CyberRelayer.sol";

import "forge-std/console.sol";
import "forge-std/Test.sol";

contract CyberRelayerTest is Test {
    address public owner = address(0x1);
    address public relayer = address(0x2);
    address public alice = address(0x3);
    address public bob = address(0x4);
    CyberRelayer public cyberRelayer;
    address public destinationContract;

    event Relayed(bytes32 relayId);

    function setUp() public {
        cyberRelayer = new CyberRelayer(owner);
        vm.startPrank(owner);
        cyberRelayer.grantRole(keccak256("RELAYER_ROLE"), relayer);
        destinationContract = address(new DestinationContract());
    }

    /* solhint-disable func-name-mixedcase */

    function testRelayGas() public {
        vm.deal(relayer, 1 ether);
        vm.startPrank(relayer);
        bytes32 relayId = keccak256(bytes("random string"));
        vm.expectEmit(true, true, true, true);
        emit Relayed(relayId);
        cyberRelayer.relay{ value: 1 ether }(relayId, alice, 1 ether, "");
        assertEq(alice.balance, 1 ether);
        assertEq(relayer.balance, 0);
    }

    function testReplayProtection() public {
        vm.deal(relayer, 2 ether);
        vm.startPrank(relayer);
        bytes32 relayId = keccak256(bytes("random string"));
        cyberRelayer.relay{ value: 1 ether }(relayId, alice, 1 ether, "");

        vm.expectRevert("ALREADY_RELAYED");
        cyberRelayer.relay{ value: 1 ether }(relayId, alice, 1 ether, "");
    }

    function testRelayOtherContract() public {
        vm.deal(relayer, 2 ether);
        vm.startPrank(relayer);
        bytes32 relayId = keccak256(bytes("random string"));
        cyberRelayer.relay{ value: 1 ether }(
            relayId,
            destinationContract,
            1 ether,
            abi.encodeWithSelector(DestinationContract.add.selector, 10)
        );
        assertEq(DestinationContract(destinationContract).counter(), 10);
    }

    function testRelayOtherContractRevert() public {
        vm.deal(relayer, 2 ether);
        vm.startPrank(relayer);
        bytes32 relayId = keccak256(bytes("random string"));
        vm.expectRevert(
            abi.encodeWithSelector(
                DestinationContract.simulateAddError.selector,
                10
            )
        );
        cyberRelayer.relay{ value: 1 ether }(
            relayId,
            destinationContract,
            1 ether,
            abi.encodeWithSelector(DestinationContract.simulateAdd.selector, 10)
        );
    }
    /* solhint-disable func-name-mixedcase */
}

contract DestinationContract {
    uint256 public counter;
    error simulateAddError(uint256 value);

    function add(uint256 value) public payable {
        counter = counter + value;
    }

    function simulateAdd(uint256 value) public payable returns (uint256 ret) {
        counter = counter + value;
        ret = counter;
        revert simulateAddError(counter);
    }
}
