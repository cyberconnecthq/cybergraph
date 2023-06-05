// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library Constants {
    // EIP712 TypeHash
    bytes32 internal constant _PERMIT_TYPEHASH =
        keccak256(
            "permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"
        );
    uint16 internal constant _MAX_BPS = 10000;
}
