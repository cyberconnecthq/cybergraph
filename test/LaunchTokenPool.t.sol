// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { LaunchTokenPool } from "../src/periphery/LaunchTokenPool.sol";
import { Create2Deployer } from "../src/deployer/Create2Deployer.sol";

import { MockERC20 } from "./utils/MockERC20.sol";

import "forge-std/console.sol";
import "forge-std/Test.sol";

contract LaunchTokenPoolTest is Test {
    bytes32 constant SALT = keccak256(bytes("CCV3"));

    address public owner = address(0x1);
    address public alice = address(0x2);
    address public bob = address(0x3);

    LaunchTokenPool public lb;
    MockERC20 public mockToken;

    event Deposit(address to, uint256 amount);
    event WithdrawCyber(address to, uint256 amount);
    event WithdrawERC20(address currency, address to, uint256 amount);

    function setUp() public {
        mockToken = new MockERC20();
        Create2Deployer dc = new Create2Deployer();
        address launchTokenPool = dc.deploy(
            abi.encodePacked(
                type(LaunchTokenPool).creationCode,
                abi.encode(owner, mockToken)
            ),
            SALT
        );
        lb = LaunchTokenPool(launchTokenPool);
    }

    /* solhint-disable func-name-mixedcase */
    function testDeposit() public {
        mockToken.mint(alice, 1 ether);
        require(mockToken.balanceOf(alice) == 1 ether, "WRONG_BAL");
        vm.startPrank(alice);

        mockToken.approve(address(lb), 1 ether);

        vm.expectEmit(true, true, true, true);
        emit Deposit(bob, 1 ether);
        lb.deposit(bob, 1 ether);

        require(mockToken.balanceOf(alice) == 0, "WRONG_BAL");
        require(lb.deposits(bob) == 1 ether, "WRONG_DEPOSIT");
        require(lb.totalDeposits() == 1 ether, "WRONG_DEPOSIT");
    }

    function testWithdrawCyber() public {
        mockToken.mint(alice, 1 ether);
        vm.startPrank(alice);
        mockToken.approve(address(lb), 1 ether);
        lb.deposit(bob, 1 ether);

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit WithdrawCyber(owner, 1 ether);
        lb.withdraw(owner, 1 ether);
        require(mockToken.balanceOf(owner) == 1 ether, "WRONG_BAL");
    }

    function testWithdrawERC20() public {
        mockToken.mint(alice, 1 ether);
        vm.startPrank(alice);
        mockToken.approve(address(lb), 1 ether);
        lb.deposit(bob, 1 ether);

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit WithdrawERC20(address(mockToken), owner, 1 ether);
        lb.withdrawERC20(address(mockToken), owner, 1 ether);
        require(mockToken.balanceOf(owner) == 1 ether, "WRONG_BAL");
    }

    function testWithdrawNotOwner() public {
        mockToken.mint(alice, 1 ether);
        vm.startPrank(alice);
        mockToken.approve(address(lb), 1 ether);
        lb.deposit(bob, 1 ether);

        vm.expectRevert("Ownable: caller is not the owner");
        lb.withdraw(bob, 1 ether);
    }

    function testPauseNotOwner() public {
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        lb.pause();
    }

    function testUnpauseNotOwner() public {
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        lb.unpause();
    }

    function testTransferNativeTokenFail() public {
        vm.startPrank(owner);
        vm.deal(owner, 1 ether);
        (bool success, ) = address(lb).call{ value: 1 ether }("");
        require(!success, "SEND_NATIVE_TOKEN_SHOULD_FAIL");
    }

    /* solhint-disable func-name-mixedcase */
}
