// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { YumeRelayGate } from "../src/periphery/YumeRelayGate.sol";
import { YumeMintNFTRelayHook } from "../src/periphery/YumeMintNFTRelayHook.sol";
import { RelayParams, IYumeRelayGateHook } from "../src/interfaces/IYumeRelayGateHook.sol";

import "forge-std/console.sol";
import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract YumeRelayTest is Test {
    address public owner = address(0x1);
    address public alice = address(0x2);
    address public bob = address(0x3);
    address public charlie = address(0x4);
    address public entryPoint = address(0x5);
    address public nft = address(0x6);
    uint256 public tokenId = 1;
    uint256 public amount = 1;
    bytes32 public requestId =
        0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 public requestId2 =
        0x1000000000000000000000000000000000000000000000000000000000000000;

    YumeRelayGate relayGate;
    YumeMintNFTRelayHook hook;

    function setUp() public {
        relayGate = new YumeRelayGate();
        relayGate.initialize(owner);
        hook = new YumeMintNFTRelayHook(owner);
    }

    event MintPriceConfigUpdated(
        uint256 chainId,
        address entryPoint,
        address nft,
        uint256 tokenId,
        bool enabled,
        address recipient,
        uint256 price
    );

    event MintFeeConfigUpdated(
        uint256 chainId,
        bool enabled,
        address recipient,
        uint256 price
    );

    event Relay(
        bytes32 requestId,
        address from,
        uint256 destinationChainId,
        address destination,
        uint256 value,
        bytes callData
    );

    event DestinationUpdated(
        uint256 chainId,
        address destination,
        bool enabled,
        address hook
    );

    /* solhint-disable func-name-mixedcase */

    function testHookConfigNotOwner() public {
        vm.prank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        hook.configMintFee(1, true, alice, 1 ether);

        vm.prank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        hook.configMintPrice(1, entryPoint, nft, tokenId, true, alice, 1 ether);
    }

    function testHookConfigMintFee() public {
        vm.prank(owner);

        vm.expectEmit(false, false, false, true);
        emit MintFeeConfigUpdated(1, true, alice, 1 ether);

        hook.configMintFee(1, true, alice, 1 ether);

        (bool enabled, address recipient, uint256 fee) = hook.mintFeeConfigs(1);
        require(enabled, "WRONG_ENABLED");
        require(fee == 1 ether, "WRONG_FEE");
        require(recipient == alice, "WRONG_RECIPIENT");
    }

    function testHookBatchConfigMintFee() public {
        vm.prank(owner);

        YumeMintNFTRelayHook.BatchConfigMintFeeParams[]
            memory params = new YumeMintNFTRelayHook.BatchConfigMintFeeParams[](
                2
            );
        params[0] = YumeMintNFTRelayHook.BatchConfigMintFeeParams(
            1,
            true,
            alice,
            1 ether
        );
        params[1] = YumeMintNFTRelayHook.BatchConfigMintFeeParams(
            2,
            true,
            bob,
            2 ether
        );

        vm.expectEmit(false, false, false, true);
        emit MintFeeConfigUpdated(1, true, alice, 1 ether);
        vm.expectEmit(false, false, false, true);
        emit MintFeeConfigUpdated(2, true, bob, 2 ether);

        hook.batchConfigMintFee(params);

        (bool enabled, address recipient, uint256 fee) = hook.mintFeeConfigs(1);
        require(enabled, "WRONG_ENABLED");
        require(fee == 1 ether, "WRONG_FEE");
        require(recipient == alice, "WRONG_RECIPIENT");

        (bool enabled2, address recipient2, uint256 fee2) = hook.mintFeeConfigs(
            2
        );
        require(enabled2, "WRONG_ENABLED");
        require(fee2 == 2 ether, "WRONG_FEE");
        require(recipient2 == bob, "WRONG_RECIPIENT");
    }

    function testHookConfigMintPrice() public {
        vm.startPrank(owner);

        vm.expectRevert("INVALID_CHAIN_ID");
        hook.configMintPrice(1, entryPoint, nft, tokenId, true, alice, 1 ether);

        vm.expectEmit(false, false, false, true);
        emit MintFeeConfigUpdated(1, true, alice, 1 ether);
        hook.configMintFee(1, true, alice, 1 ether);

        vm.expectEmit(false, false, false, true);
        emit MintPriceConfigUpdated(
            1,
            entryPoint,
            nft,
            tokenId,
            true,
            bob,
            1 ether
        );
        hook.configMintPrice(1, entryPoint, nft, tokenId, true, bob, 1 ether);

        (bool enabled, address recipient, uint256 price) = hook
            .mintPriceConfigs(1, entryPoint, nft, tokenId);
        require(enabled, "WRONG_ENABLED");
        require(price == 1 ether, "WRONG_PRICE");
        require(recipient == bob, "WRONG_RECIPIENT");
    }

    function testHookWithoutConfig() public {
        vm.prank(charlie);
        vm.deal(charlie, 10 ether);
        vm.expectRevert("MINT_FEE_NOT_ALLOWED");
        bytes memory callData = abi.encode(charlie, nft, tokenId, amount);
        hook.processRelay{ value: 2 ether }(charlie, 1, entryPoint, callData);
    }

    function testHookProcessRelay() public {
        vm.startPrank(owner);

        vm.expectEmit(false, false, false, true);
        emit MintFeeConfigUpdated(1, true, alice, 1 ether);
        hook.configMintFee(1, true, alice, 1 ether);

        vm.expectEmit(false, false, false, true);
        emit MintPriceConfigUpdated(
            1,
            entryPoint,
            nft,
            tokenId,
            true,
            bob,
            1 ether
        );
        hook.configMintPrice(1, entryPoint, nft, tokenId, true, bob, 1 ether);

        vm.stopPrank();

        vm.startPrank(charlie);

        vm.deal(charlie, 10 ether);
        bytes memory callData = abi.encode(charlie, nft, tokenId, amount);

        vm.expectRevert("INSUFFICIENT_FUNDS");
        hook.processRelay{ value: 1 ether }(charlie, 1, entryPoint, callData);

        RelayParams memory relayParams = hook.processRelay{ value: 2 ether }(
            charlie,
            1,
            entryPoint,
            callData
        );
        require(relayParams.to == entryPoint, "WRONG_TO");
        require(relayParams.value == 1 ether, "WRONG_VALUE");
        require(
            keccak256(relayParams.callData) ==
                keccak256(
                    abi.encodeWithSignature(
                        "mint(address, address, uint256, uint256)",
                        charlie,
                        nft,
                        tokenId,
                        amount
                    )
                ),
            "WRONG_CALL_DATA"
        );

        require(alice.balance == 1 ether, "WRONG_ALICE_BAL");
        require(bob.balance == 1 ether, "WRONG_BOB_BAL");
        require(charlie.balance == 8 ether, "WRONG_CHARLIE_BAL");
        require(address(hook).balance == 0, "WRONG_CONTRACT_BAL");

        hook.processRelay{ value: 3 ether }(charlie, 1, entryPoint, callData);
        require(alice.balance == 2 ether, "WRONG_ALICE_BAL");
        require(bob.balance == 2 ether, "WRONG_BOB_BAL");
        require(charlie.balance == 6 ether, "WRONG_CHARLIE_BAL");
        require(address(hook).balance == 0, "WRONG_CONTRACT_BAL");

        vm.stopPrank();
    }

    function testRelayGateConfigNotOwner() public {
        vm.prank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        relayGate.setDestination(1, entryPoint, true, address(hook));

        vm.prank(alice);

        YumeRelayGate.BatchSetDestinationParams[]
            memory params = new YumeRelayGate.BatchSetDestinationParams[](2);
        params[0] = YumeRelayGate.BatchSetDestinationParams(
            1,
            entryPoint,
            true,
            address(hook)
        );
        params[1] = YumeRelayGate.BatchSetDestinationParams(
            2,
            entryPoint,
            true,
            address(hook)
        );

        vm.expectRevert("Ownable: caller is not the owner");
        relayGate.batchSetDestination(params);
    }

    function testRelayGateSetDestination() public {
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit DestinationUpdated(1, entryPoint, true, address(hook));
        relayGate.setDestination(1, entryPoint, true, address(hook));

        (bool enabled, IYumeRelayGateHook hook) = relayGate.relayDestinations(
            1,
            entryPoint
        );
        require(enabled, "WRONG_ENABLED");
        require(hook == hook, "WRONG_HOOK");
    }

    function testRelayGateBatchSetDestination() public {
        vm.prank(owner);

        YumeRelayGate.BatchSetDestinationParams[]
            memory params = new YumeRelayGate.BatchSetDestinationParams[](2);
        params[0] = YumeRelayGate.BatchSetDestinationParams(
            1,
            entryPoint,
            true,
            address(hook)
        );
        params[1] = YumeRelayGate.BatchSetDestinationParams(
            2,
            entryPoint,
            true,
            address(hook)
        );

        vm.expectEmit(false, false, false, true);
        emit DestinationUpdated(1, entryPoint, true, address(hook));
        vm.expectEmit(false, false, false, true);
        emit DestinationUpdated(2, entryPoint, true, address(hook));

        relayGate.batchSetDestination(params);

        (bool enabled, IYumeRelayGateHook hookAddr) = relayGate
            .relayDestinations(1, entryPoint);
        require(enabled, "WRONG_ENABLED");
        require(hookAddr == hook, "WRONG_HOOK");

        (bool enabled2, IYumeRelayGateHook hookAddr2) = relayGate
            .relayDestinations(2, entryPoint);
        require(enabled2, "WRONG_ENABLED");
        require(hookAddr2 == hook, "WRONG_HOOK");
    }

    function testRelayGateRelayWithoutDestination() public {
        vm.prank(charlie);
        vm.deal(charlie, 10 ether);
        vm.expectRevert("DESTINATION_DISABLED");
        relayGate.relay{ value: 2 ether }(
            requestId,
            1,
            entryPoint,
            abi.encode(charlie, nft, tokenId, amount)
        );
    }

    function testRelayGateRelay() public {
        vm.startPrank(owner);

        vm.expectEmit(false, false, false, true);
        emit DestinationUpdated(1, entryPoint, true, address(hook));
        relayGate.setDestination(1, entryPoint, true, address(hook));

        vm.expectEmit(false, false, false, true);
        emit MintFeeConfigUpdated(1, true, alice, 1 ether);
        hook.configMintFee(1, true, alice, 1 ether);

        vm.expectEmit(false, false, false, true);
        emit MintPriceConfigUpdated(
            1,
            entryPoint,
            nft,
            tokenId,
            true,
            bob,
            1 ether
        );
        hook.configMintPrice(1, entryPoint, nft, tokenId, true, bob, 1 ether);

        vm.stopPrank();

        vm.startPrank(charlie);
        vm.deal(charlie, 10 ether);

        vm.expectRevert("INSUFFICIENT_FUNDS");
        relayGate.relay(
            requestId,
            1,
            entryPoint,
            abi.encode(charlie, nft, tokenId, amount)
        );

        vm.expectEmit(false, false, false, true);
        emit Relay(
            requestId,
            charlie,
            1,
            entryPoint,
            1 ether,
            abi.encodeWithSignature(
                "mint(address, address, uint256, uint256)",
                charlie,
                nft,
                tokenId,
                amount
            )
        );
        relayGate.relay{ value: 2 ether }(
            requestId,
            1,
            entryPoint,
            abi.encode(charlie, nft, tokenId, amount)
        );

        require(alice.balance == 1 ether, "WRONG_ALICE_BAL");
        require(bob.balance == 1 ether, "WRONG_BOB_BAL");
        require(charlie.balance == 8 ether, "WRONG_CHARLIE_BAL");
        require(address(hook).balance == 0, "WRONG_CONTRACT_BAL");
        require(address(relayGate).balance == 0, "WRONG_CONTRACT_BAL");

        vm.expectRevert("REQUEST_ID_USED");
        relayGate.relay{ value: 2 ether }(
            requestId,
            1,
            entryPoint,
            abi.encode(charlie, nft, tokenId, amount)
        );

        vm.expectEmit(false, false, false, true);
        emit Relay(
            requestId2,
            charlie,
            1,
            entryPoint,
            1 ether,
            abi.encodeWithSignature(
                "mint(address, address, uint256, uint256)",
                charlie,
                nft,
                tokenId,
                amount
            )
        );
        relayGate.relay{ value: 3 ether }(
            requestId2,
            1,
            entryPoint,
            abi.encode(charlie, nft, tokenId, amount)
        );
        require(alice.balance == 2 ether, "WRONG_ALICE_BAL");
        require(bob.balance == 2 ether, "WRONG_BOB_BAL");
        require(charlie.balance == 6 ether, "WRONG_CHARLIE_BAL");
        require(address(hook).balance == 0, "WRONG_CONTRACT_BAL");
        require(address(relayGate).balance == 0, "WRONG_CONTRACT_BAL");

        vm.stopPrank();
    }

    /* solhint-disable func-name-mixedcase */
}
