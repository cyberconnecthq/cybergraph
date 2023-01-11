// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.9.0;

library SignatureValidator {
    // The signature format is a compact form of:
    //   {bytes32 r}{bytes32 s}{uint8 v}
    // Compact means, uint8 is not padded to 32 bytes.
    function signatureSplit(
        bytes memory signatures,
        uint256 pos
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    function recoverSigner(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address signer) {
        (uint8 v, bytes32 r, bytes32 s) = signatureSplit(signature, 0);
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "INVALID_S_VALUE"
        );
        require(v == 27 || v == 28, "INVALID_V_VALUE");

        signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "INVALID_SIGNER");
    }
}
