// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

import { IERC1271 } from "../interfaces/IERC1271.sol";

contract Authenticator is IERC1271 {
    bytes4 private constant SELECTOR_ERC1271_BYTES32_BYTES = 0x1626ba7e;

    function checkSignature(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) public view {}

    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signatures
    ) external view override returns (bytes4) {
        // Validate signatures
        // if (_signatureValidation(_subDigest(_hash), _signatures)) {
        //     return SELECTOR_ERC1271_BYTES32_BYTES;
        // }
        return SELECTOR_ERC1271_BYTES32_BYTES;
    }
}
