// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "../src/periphery/CyberStakingPool.sol";

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
            "bridge(address bridge,address recipient,address[] assets,uint256[] amounts,uint256 deadline,uint256 nonce)"
        );

    event Deposit(
        uint256 logId,
        address assetOwner,
        address asset,
        uint256 amount
    );
    event Withdraw(
        uint256 logId,
        address assetOwner,
        address[] assets,
        uint256[] amounts
    );
    event Bridge(
        uint256 logId,
        address bridge,
        address assetOwner,
        address recipient,
        address[] assets,
        uint256[] amounts
    );
    event SetAssetWhitelist(address asset, bool isWhitelisted);
    event SetBridgeWhitelist(address bridge, bool isWhitelisted);

    function setUp() public {
        mockToken = new MockERC20();
        weth = new WETH();
        pool = new CyberStakingPool(address(weth), owner);
        mockBridge = new MockBridge(address(pool));
        vm.startPrank(owner);
        bytes32 role = keccak256(bytes("OPERATOR_ROLE"));
        console.logBytes32(role);
        pool.grantRole(role, owner);
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
    }

    function testPaused() public {
        vm.deal(owner, 1 ether);
        pool.pause();

        vm.expectRevert("Pausable: paused");
        pool.deposit(address(mockToken), 1 ether);
        vm.expectRevert("Pausable: paused");
        pool.depositETH{ value: 1 ether }();
        vm.expectRevert("Pausable: paused");
        (bool success, ) = payable(pool).call{ value: 1 ether }("");
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
        emit Deposit(1, alice, address(weth), 1 ether);
        (bool success, ) = payable(pool).call{ value: 1 ether }("");

        assertEq(alice.balance, 0);
        assertEq(address(pool).balance, 0);
        assertEq(weth.balanceOf(address(pool)), 2 ether);
        assertEq(pool.balance(address(weth), alice), 2 ether);
        assertEq(pool.totalBalance(address(weth)), 2 ether);
    }

    function testWithdraw() public {
        mockToken.mint(alice, 2 ether);
        vm.startPrank(alice);

        mockToken.approve(address(pool), 2 ether);
        pool.deposit(address(mockToken), 2 ether);

        vm.expectEmit(true, true, true, true);
        address[] memory assets = new address[](1);
        assets[0] = address(mockToken);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;
        emit Withdraw(1, alice, assets, amounts);
        pool.withdraw(assets, amounts);

        assertEq(mockToken.balanceOf(alice), 1 ether);
        assertEq(mockToken.balanceOf(address(pool)), 1 ether);
        assertEq(pool.balance(address(mockToken), alice), 1 ether);
        assertEq(pool.totalBalance(address(mockToken)), 1 ether);

        amounts[0] = 2 ether;
        vm.expectRevert("INSUFFICIENT_BALANCE");
        pool.withdraw(assets, amounts);
    }

    function testBridge() public {
        mockToken.mint(alice, 2 ether);
        vm.startPrank(alice);

        mockToken.approve(address(pool), 2 ether);
        pool.deposit(address(mockToken), 2 ether);

        address[] memory assets = new address[](1);
        assets[0] = address(mockToken);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;
        BridgeParams memory params = BridgeParams(
            address(mockBridge),
            alice,
            assets,
            amounts
        );

        vm.expectRevert("BRIDGE_NOT_WHITELISTED");
        pool.bridge(params);

        vm.startPrank(owner);
        pool.setBridgeWhitelist(address(mockBridge), true);

        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit Bridge(1, address(mockBridge), alice, alice, assets, amounts);

        pool.bridge(params);
        assertEq(mockToken.balanceOf(alice), 1 ether);
        assertEq(mockToken.balanceOf(address(pool)), 1 ether);
        assertEq(mockToken.balanceOf(address(bob)), 0 ether);
        assertEq(pool.balance(address(mockToken), alice), 1 ether);
        assertEq(pool.totalBalance(address(mockToken)), 1 ether);

        vm.expectEmit(true, true, true, true);
        emit Bridge(2, address(mockBridge), alice, bob, assets, amounts);
        params.recipient = bob;
        pool.bridge(params);
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

        address[] memory assets = new address[](1);
        assets[0] = address(mockToken);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;

        bytes memory sig = _generateSig(
            aliceSk,
            address(mockBridge),
            alice,
            alice,
            assets,
            amounts,
            block.timestamp + 100
        );
        vm.startPrank(bob);
        vm.expectEmit(true, true, true, true);
        emit Bridge(1, address(mockBridge), alice, alice, assets, amounts);
        BridgeParams memory bridgeParams = BridgeParams(
            address(mockBridge),
            alice,
            assets,
            amounts
        );
        EIP712Signature memory signature = EIP712Signature(
            block.timestamp + 100,
            sig
        );
        pool.bridgeWithSig(alice, bridgeParams, signature);
        assertEq(mockToken.balanceOf(alice), 1 ether);
        assertEq(mockToken.balanceOf(address(pool)), 1 ether);
        assertEq(mockToken.balanceOf(address(bob)), 0 ether);
        assertEq(pool.balance(address(mockToken), alice), 1 ether);
        assertEq(pool.totalBalance(address(mockToken)), 1 ether);

        // test nonce ++
        vm.expectRevert("INVALID_SIGNATURE");
        pool.bridgeWithSig(alice, bridgeParams, signature);

        sig = _generateSig(
            aliceSk,
            address(mockBridge),
            alice,
            bob,
            assets,
            amounts,
            block.timestamp + 100
        );
        signature.signature = sig;
        bridgeParams.recipient = bob;
        vm.expectEmit(true, true, true, true);
        emit Bridge(2, address(mockBridge), alice, bob, assets, amounts);
        pool.bridgeWithSig(alice, bridgeParams, signature);
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
            assets,
            amounts,
            block.timestamp - 100
        );
        vm.expectRevert("SIGNATURE_EXPIRED");
        signature.deadline = block.timestamp - 100;
        signature.signature = sig;
        pool.bridgeWithSig(alice, bridgeParams, signature);
    }

    function testInvalidInputs() public {
        pool.setBridgeWhitelist(address(mockBridge), true);

        address[] memory assets = new address[](1);
        assets[0] = address(mockToken);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;

        BridgeParams memory bridgeParams = BridgeParams(
            address(mockBridge),
            alice,
            assets,
            amounts
        );
        bytes memory mockSig = new bytes(0);
        EIP712Signature memory signature = EIP712Signature(
            block.timestamp + 100,
            mockSig
        );
        vm.expectRevert("INVALID_LENGTH");
        pool.bridgeWithSig(alice, bridgeParams, signature);

        vm.expectRevert("INVALID_LENGTH");
        pool.bridge(bridgeParams);

        amounts = new uint256[](1);
        amounts[0] = 1 ether;
        bridgeParams.amounts = amounts;
        bridgeParams.recipient = address(0);
        vm.expectRevert("RECIPIENT_ZERO_ADDRESS");
        pool.bridge(bridgeParams);

        vm.expectRevert("RECIPIENT_ZERO_ADDRESS");
        pool.bridgeWithSig(alice, bridgeParams, signature);
    }

    function _generateSig(
        uint256 signerPk,
        address bridgeAddress,
        address assetOwner,
        address recipient,
        address[] memory assets,
        uint256[] memory amounts,
        uint256 deadline
    ) internal view returns (bytes memory) {
        uint256 nonce = pool.nonces(assetOwner);
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(pool),
            keccak256(
                abi.encode(
                    BRIDGE_TYPEHASH,
                    bridgeAddress,
                    recipient,
                    keccak256(abi.encodePacked(assets)),
                    keccak256(abi.encodePacked(amounts)),
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
