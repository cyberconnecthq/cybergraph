// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { LaunchBridge } from "../src/periphery/LaunchBridge.sol";
import { Create2Deployer } from "../src/deployer/Create2Deployer.sol";

import { MockERC20 } from "./utils/MockERC20.sol";

import "forge-std/console.sol";
import "forge-std/Test.sol";

contract LaunchBridgeTest is Test {
    bytes32 constant SALT = keccak256(bytes("CCV3"));

    address public owner = address(0x1);
    address public alice = address(0x2);
    address public bob = address(0x3);

    LaunchBridge public lb;
    MockERC20 public mockToken;

    event Deposit(address to, uint256 amount);
    event Withdraw(address to, uint256 amount);

    function setUp() public {
        mockToken = new MockERC20();
        Create2Deployer dc = new Create2Deployer();
        address launchBridgeImpl = dc.deploy(
            abi.encodePacked(type(LaunchBridge).creationCode),
            SALT
        );

        address launchBridgeProxy = dc.deploy(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    launchBridgeImpl,
                    abi.encodeWithSelector(
                        LaunchBridge.initialize.selector,
                        owner,
                        mockToken
                    )
                )
            ),
            SALT
        );
        lb = LaunchBridge(launchBridgeProxy);
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

    function testWithdraw() public {
        mockToken.mint(alice, 1 ether);
        vm.startPrank(alice);
        mockToken.approve(address(lb), 1 ether);
        lb.deposit(bob, 1 ether);

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit Withdraw(owner, 1 ether);
        lb.withdraw(owner, 1 ether);
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

    function testUpgradeNotOwner() public {
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        lb.upgradeTo(bob);
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
    /* solhint-disable func-name-mixedcase */
}
