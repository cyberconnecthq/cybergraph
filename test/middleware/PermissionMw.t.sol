// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";
import { TestLib712 } from "../utils/TestLib712.sol";
import { Soul } from "../../src/core/Soul.sol";
import { PermissionMw } from "../../src/middlewares/PermissionMw.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { MiddlewareManager } from "../../src/core/MiddlewareManager.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";

import "forge-std/console.sol";

contract PermissionMwTest is TestIntegrationBase {
    address public mw;
    uint256 public aliceSk = 666;
    address public alice = vm.addr(aliceSk);
    uint256 public bobSk = 888;
    address public bob = vm.addr(bobSk);

    string constant BOB_ISSUED_1_URL = "mf.com";

    function setUp() public {
        _setUp();
        Soul(addrs.soul).createSoul(alice, true);
        Soul(addrs.soul).createSoul(bob, false);
        mw = address(new PermissionMw(addrs.engine));

        vm.prank(protocolOwner);
        MiddlewareManager(addrs.manager).allowMw(address(mw), true);
    }

    /* solhint-disable func-name-mixedcase */

    function testSetMwWithInvalidParams() public {
        vm.startPrank(alice);
        vm.expectRevert("INVALID_SIGNER");
        CyberEngine(addrs.engine).issueW3st(
            DataTypes.IssueW3stParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(address(0))
        );
    }

    function test_MwSet_Collect_Success() public {
        vm.startPrank(alice);
        uint256 id = CyberEngine(addrs.engine).issueW3st(
            DataTypes.IssueW3stParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(alice)
        );

        uint256 beforeNonce = PermissionMw(mw).getNonce(
            alice,
            DataTypes.Category.W3ST,
            id,
            bob
        );

        uint256 deadline = block.timestamp + 1;
        (uint8 v, bytes32 r, bytes32 s) = _generateSig(
            bob,
            aliceSk,
            deadline,
            DataTypes.CollectParams(alice, id, 1, DataTypes.Category.W3ST)
        );

        vm.startPrank(bob);
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(alice, id, 1, DataTypes.Category.W3ST),
            abi.encode(v, r, s, deadline)
        );

        uint256 afterNonce = PermissionMw(mw).getNonce(
            alice,
            DataTypes.Category.W3ST,
            id,
            bob
        );

        assertEq(beforeNonce + 1, afterNonce);
    }

    function test_MwSet_SetMwDataWithWrongCaller_Revert() public {
        vm.startPrank(alice);
        vm.expectRevert("NON_ENGINE_ADDRESS");
        PermissionMw(mw).setMwData(
            alice,
            DataTypes.Category.W3ST,
            0,
            abi.encode(alice)
        );
    }

    function test_MwSet_CollectWithExpiredSig_Revert() public {
        vm.startPrank(alice);
        uint256 id = CyberEngine(addrs.engine).issueW3st(
            DataTypes.IssueW3stParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(alice)
        );

        uint256 deadline = block.timestamp - 1;
        (uint8 v, bytes32 r, bytes32 s) = _generateSig(
            bob,
            aliceSk,
            deadline,
            DataTypes.CollectParams(alice, id, 1, DataTypes.Category.W3ST)
        );

        vm.startPrank(bob);
        vm.expectRevert("DEADLINE_EXCEEDED");
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(alice, id, 1, DataTypes.Category.W3ST),
            abi.encode(v, r, s, deadline)
        );
    }

    function test_MwSet_CollectWithWrongSig_Revert() public {
        vm.startPrank(alice);
        uint256 id = CyberEngine(addrs.engine).issueW3st(
            DataTypes.IssueW3stParams(alice, BOB_ISSUED_1_URL, mw, true),
            abi.encode(alice)
        );

        uint256 deadline = block.timestamp + 1;
        (uint8 v, bytes32 r, bytes32 s) = _generateSig(
            bob,
            aliceSk,
            deadline,
            DataTypes.CollectParams(alice, id, 2, DataTypes.Category.W3ST)
        );

        vm.startPrank(bob);
        vm.expectRevert("INVALID_SIGNATURE");
        CyberEngine(addrs.engine).collect(
            DataTypes.CollectParams(alice, id, 1, DataTypes.Category.W3ST),
            abi.encode(v, r, s, deadline)
        );
    }

    function _generateSig(
        address collector,
        uint256 signerPk,
        uint256 deadline,
        DataTypes.CollectParams memory params
    ) internal view returns (uint8, bytes32, bytes32) {
        uint256 nonce = PermissionMw(mw).getNonce(
            params.account,
            params.category,
            params.id,
            collector
        );
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(mw),
            keccak256(
                abi.encode(
                    PermissionMw(mw).COLLECT_TYPEHASH(),
                    collector,
                    params.account,
                    params.category,
                    params.id,
                    params.amount,
                    nonce,
                    deadline
                )
            ),
            "PermissionMw",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        return (v, r, s);
    }

    /* solhint-disable func-name-mixedcase */
}
