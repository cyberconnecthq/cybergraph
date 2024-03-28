// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { CyberStakingPool } from "../src/periphery/CyberStakingPool.sol";

import { MockERC20 } from "./utils/MockERC20.sol";
import { MockBridge } from "./utils/MockBridge.sol";
import { WETH } from "./utils/WETH.sol";
import { TestLib712 } from "./utils/TestLib712.sol";

import "forge-std/console.sol";
import "forge-std/Test.sol";

contract CyberStakingPoolTest is Test {
    uint256 public aliceSk = 666;
    address public alice = vm.addr(aliceSk);
    address public owner = address(0x1);
    address public bob = address(0x3);

    CyberStakingPool public pool;
    MockERC20 public mockToken;
    MockBridge public mockBridge;
    WETH public weth;

    bytes32 private constant BRIDGE_TYPEHASH =
        keccak256(
            "bridge(address bridge,address assetOwner,address receipient,address asset,uint256 amount,uint256 deadline,uint256 nonce)"
        );

    event Deposit(uint256 logId, address to, address asset, uint256 amount);
    event Withdraw(
        uint256 logId,
        address assetOwner,
        address recipient,
        address asset,
        uint256 amount
    );
    event Bridge(
        uint256 logId,
        address bridge,
        address assetOwner,
        address recipient,
        address asset,
        uint256 amount
    );
    event SetAssetWhitelist(address asset, bool isWhitelisted);
    event SetBridgeWhitelist(address bridge, bool isWhitelisted);

    function setUp() public {
        mockToken = new MockERC20();
        weth = new WETH();
        pool = new CyberStakingPool(address(weth), owner);
        mockBridge = new MockBridge(address(pool));
        vm.startPrank(owner);
        pool.grantRole(keccak256(bytes("OPERATOR_ROLE")), owner);
        pool.setAssetWhitelist(address(mockToken), true);
    }

    /* solhint-disable func-name-mixedcase */
    function testDeposit() public {
        mockToken.mint(alice, 2 ether);
        vm.startPrank(alice);

        mockToken.approve(address(pool), 2 ether);

        vm.expectEmit(true, true, true, true);
        emit Deposit(0, alice, address(mockToken), 1 ether);
        pool.deposit(address(mockToken), 1 ether);

        assertEq(mockToken.balanceOf(alice), 1 ether);
        assertEq(mockToken.balanceOf(address(pool)), 1 ether);
        assertEq(pool.balance(address(mockToken), alice), 1 ether);
        assertEq(pool.totalBalance(address(mockToken)), 1 ether);

        vm.expectEmit(true, true, true, true);
        emit Deposit(1, bob, address(mockToken), 1 ether);
        pool.depositFor(bob, address(mockToken), 1 ether);

        assertEq(mockToken.balanceOf(alice), 0);
        assertEq(mockToken.balanceOf(address(pool)), 2 ether);
        assertEq(pool.balance(address(mockToken), bob), 1 ether);
        assertEq(pool.totalBalance(address(mockToken)), 2 ether);
    }

    function testPaused() public {
        vm.deal(owner, 1 ether);
        pool.pause();

        vm.expectRevert("Pausable: paused");
        pool.deposit(address(mockToken), 1 ether);
        vm.expectRevert("Pausable: paused");
        pool.depositFor(bob, address(mockToken), 1 ether);
        vm.expectRevert("Pausable: paused");
        pool.depositETH{ value: 1 ether }();
        vm.expectRevert("Pausable: paused");
        pool.depositETHFor{ value: 1 ether }(owner);
    }

    function testDepositETH() public {
        vm.deal(alice, 2 ether);

        vm.startPrank(alice);

        vm.expectEmit(true, true, true, true);
        emit Deposit(0, alice, address(weth), 1 ether);
        pool.depositETH{ value: 1 ether }();

        assertEq(alice.balance, 1 ether);
        assertEq(address(pool).balance, 0);
        assertEq(weth.balanceOf(address(pool)), 1 ether);
        assertEq(pool.balance(address(weth), alice), 1 ether);
        assertEq(pool.totalBalance(address(weth)), 1 ether);

        vm.expectEmit(true, true, true, true);
        emit Deposit(1, bob, address(weth), 1 ether);
        pool.depositETHFor{ value: 1 ether }(bob);

        assertEq(alice.balance, 0);
        assertEq(address(pool).balance, 0);
        assertEq(weth.balanceOf(address(pool)), 2 ether);
        assertEq(pool.balance(address(weth), bob), 1 ether);
        assertEq(pool.totalBalance(address(weth)), 2 ether);
    }

    function testWithdraw() public {
        mockToken.mint(alice, 2 ether);
        vm.startPrank(alice);

        mockToken.approve(address(pool), 2 ether);
        pool.deposit(address(mockToken), 2 ether);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(1, alice, bob, address(mockToken), 1 ether);
        pool.withdraw(bob, address(mockToken), 1 ether);

        assertEq(mockToken.balanceOf(alice), 0 ether);
        assertEq(mockToken.balanceOf(address(pool)), 1 ether);
        assertEq(mockToken.balanceOf(address(bob)), 1 ether);
        assertEq(pool.balance(address(mockToken), alice), 1 ether);
        assertEq(pool.totalBalance(address(mockToken)), 1 ether);

        vm.expectRevert("INSUFFICIENT_BALANCE");
        pool.withdraw(bob, address(mockToken), 2 ether);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(2, alice, alice, address(mockToken), 1 ether);
        pool.withdraw(alice, address(mockToken), 1 ether);

        assertEq(mockToken.balanceOf(alice), 1 ether);
        assertEq(mockToken.balanceOf(address(pool)), 0 ether);
        assertEq(mockToken.balanceOf(address(bob)), 1 ether);
        assertEq(pool.balance(address(mockToken), alice), 0 ether);
        assertEq(pool.totalBalance(address(mockToken)), 0 ether);
    }

    function testBridge() public {
        mockToken.mint(alice, 2 ether);
        vm.startPrank(alice);

        mockToken.approve(address(pool), 2 ether);
        pool.deposit(address(mockToken), 2 ether);

        vm.expectRevert("BRIDGE_NOT_WHITELISTED");
        pool.bridge(address(mockBridge), alice, address(mockToken), 1 ether);

        vm.startPrank(owner);
        pool.setBridgeWhitelist(address(mockBridge), true);

        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit Bridge(
            1,
            address(mockBridge),
            alice,
            alice,
            address(mockToken),
            1 ether
        );
        pool.bridge(address(mockBridge), alice, address(mockToken), 1 ether);
        assertEq(mockToken.balanceOf(alice), 1 ether);
        assertEq(mockToken.balanceOf(address(pool)), 1 ether);
        assertEq(mockToken.balanceOf(address(bob)), 0 ether);
        assertEq(pool.balance(address(mockToken), alice), 1 ether);
        assertEq(pool.totalBalance(address(mockToken)), 1 ether);

        vm.expectEmit(true, true, true, true);
        emit Bridge(
            2,
            address(mockBridge),
            alice,
            bob,
            address(mockToken),
            1 ether
        );
        pool.bridge(address(mockBridge), bob, address(mockToken), 1 ether);
        assertEq(mockToken.balanceOf(alice), 1 ether);
        assertEq(mockToken.balanceOf(address(pool)), 0 ether);
        assertEq(mockToken.balanceOf(address(bob)), 1 ether);
        assertEq(pool.balance(address(mockToken), alice), 0 ether);
        assertEq(pool.totalBalance(address(mockToken)), 0 ether);
    }

    function testBridgeWithSig() public {
        mockToken.mint(alice, 2 ether);
        pool.setBridgeWhitelist(address(mockBridge), true);
        vm.startPrank(alice);
        mockToken.approve(address(pool), 2 ether);
        pool.deposit(address(mockToken), 2 ether);

        bytes memory sig = _generateSig(
            aliceSk,
            address(mockBridge),
            alice,
            alice,
            address(mockToken),
            1 ether,
            block.timestamp + 100
        );
        vm.startPrank(bob);
        vm.expectEmit(true, true, true, true);
        emit Bridge(
            1,
            address(mockBridge),
            alice,
            alice,
            address(mockToken),
            1 ether
        );
        pool.bridgeWithSig(
            address(mockBridge),
            alice,
            alice,
            address(mockToken),
            1 ether,
            block.timestamp + 100,
            sig
        );
        assertEq(mockToken.balanceOf(alice), 1 ether);
        assertEq(mockToken.balanceOf(address(pool)), 1 ether);
        assertEq(mockToken.balanceOf(address(bob)), 0 ether);
        assertEq(pool.balance(address(mockToken), alice), 1 ether);
        assertEq(pool.totalBalance(address(mockToken)), 1 ether);

        vm.expectRevert("INVALID_SIGNATURE");
        pool.bridgeWithSig(
            address(mockBridge),
            alice,
            alice,
            address(mockToken),
            1 ether,
            block.timestamp + 100,
            sig
        );

        sig = _generateSig(
            aliceSk,
            address(mockBridge),
            alice,
            bob,
            address(mockToken),
            1 ether,
            block.timestamp + 100
        );
        vm.expectEmit(true, true, true, true);
        emit Bridge(
            2,
            address(mockBridge),
            alice,
            bob,
            address(mockToken),
            1 ether
        );
        pool.bridgeWithSig(
            address(mockBridge),
            alice,
            bob,
            address(mockToken),
            1 ether,
            block.timestamp + 100,
            sig
        );
        assertEq(mockToken.balanceOf(alice), 1 ether);
        assertEq(mockToken.balanceOf(address(pool)), 0 ether);
        assertEq(mockToken.balanceOf(address(bob)), 1 ether);
        assertEq(pool.balance(address(mockToken), alice), 0 ether);
        assertEq(pool.totalBalance(address(mockToken)), 0 ether);

        mockToken.mint(alice, 2 ether);
        vm.startPrank(alice);
        mockToken.approve(address(pool), 2 ether);
        pool.deposit(address(mockToken), 2 ether);
        vm.warp(100);
        sig = _generateSig(
            aliceSk,
            address(mockBridge),
            alice,
            bob,
            address(mockToken),
            1 ether,
            block.timestamp - 100
        );
        vm.expectRevert("SIGNATURE_EXPIRED");
        pool.bridgeWithSig(
            address(mockBridge),
            alice,
            bob,
            address(mockToken),
            1 ether,
            block.timestamp - 100,
            sig
        );
    }

    function _generateSig(
        uint256 signerPk,
        address bridgeAddress,
        address assetOwner,
        address receipient,
        address asset,
        uint256 amount,
        uint256 deadline
    ) internal view returns (bytes memory) {
        uint256 nonce = pool.nonces(assetOwner);
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(pool),
            keccak256(
                abi.encode(
                    BRIDGE_TYPEHASH,
                    bridgeAddress,
                    assetOwner,
                    receipient,
                    asset,
                    amount,
                    deadline,
                    nonce
                )
            ),
            "CyberStakingPool",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        return abi.encodePacked(r, s, v);
    }
    /* solhint-disable func-name-mixedcase */
}
