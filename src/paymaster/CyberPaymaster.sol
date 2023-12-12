// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "account-abstraction/core/BasePaymaster.sol";
import "account-abstraction/interfaces/IEntryPoint.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import { IMetaPaymaster } from "./IMetaPaymaster.sol";

contract CyberPaymaster is BasePaymaster {
    using UserOperationLib for UserOperation;

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    address public metaPaymaster;
    address public verifyingSigner;

    uint256 private constant VALID_TIMESTAMP_OFFSET = 20;
    uint256 private constant SIGNATURE_OFFSET = VALID_TIMESTAMP_OFFSET + 64;
    uint256 private constant POST_OP_OVERHEAD = 34982;

    /*//////////////////////////////////////////////////////////////
                            CONSTRACTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        IEntryPoint _entryPoint,
        address _owner
    ) BasePaymaster(_entryPoint) {
        _transferOwnership(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * return the hash we're going to sign off-chain (and validate on-chain)
     * this method is called by the off-chain service, to sign the request.
     * it is called on-chain from the validatePaymasterUserOp, to validate the signature.
     * note that this signature covers all fields of the UserOperation, except the "paymasterAndData",
     * which will carry the signature itself.
     */
    function getHash(
        UserOperation calldata userOp,
        uint48 validUntil,
        uint48 validAfter
    ) public view returns (bytes32) {
        // can't use userOp.hash(), since it contains also the paymasterAndData itself.
        return
            keccak256(
                abi.encode(
                    userOp.getSender(),
                    userOp.nonce,
                    calldataKeccak(userOp.initCode),
                    calldataKeccak(userOp.callData),
                    userOp.callGasLimit,
                    userOp.verificationGasLimit,
                    userOp.preVerificationGas,
                    userOp.maxFeePerGas,
                    userOp.maxPriorityFeePerGas,
                    block.chainid,
                    address(this),
                    validUntil,
                    validAfter
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                            PAYMASTER OVERRIDES
    //////////////////////////////////////////////////////////////*/
    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 requiredPreFund
    )
        internal
        view
        override
        returns (bytes memory context, uint256 validationData)
    {
        validationData = __validatePaymasterUserOp(
            userOp,
            userOpHash,
            requiredPreFund
        );
        if (metaPaymaster != address(0)) {
            return (
                abi.encode(userOp.maxFeePerGas, userOp.maxPriorityFeePerGas),
                validationData
            );
        } else {
            return ("", validationData);
        }
    }

    /**
     * verify our external signer signed this request.
     * the "paymasterAndData" is expected to be the paymaster and a signature over the entire request params
     * paymasterAndData[:20] : address(this)
     * paymasterAndData[20:84] : abi.encode(validUntil, validAfter)
     * paymasterAndData[84:] : signature
     */
    function __validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 /*userOpHash*/,
        uint256 /*requiredPreFund*/
    ) internal view returns (uint256) {
        (
            uint48 validUntil,
            uint48 validAfter,
            bytes calldata signature
        ) = _parsePaymasterAndData(userOp.paymasterAndData);
        // Only support 65-byte signatures, to avoid potential replay attacks.
        require(
            signature.length == 65,
            "Paymaster: invalid signature length in paymasterAndData"
        );
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            getHash(userOp, validUntil, validAfter)
        );

        // don't revert on signature failure: return SIG_VALIDATION_FAILED
        if (verifyingSigner != ECDSA.recover(hash, signature)) {
            return _packValidationData(true, validUntil, validAfter);
        }

        // no need for other on-chain validation: entire UserOp should have been checked
        // by the external service prior to signing it.
        return _packValidationData(false, validUntil, validAfter);
    }

    function _parsePaymasterAndData(
        bytes calldata paymasterAndData
    )
        internal
        pure
        returns (uint48 validUntil, uint48 validAfter, bytes calldata signature)
    {
        (validUntil, validAfter) = abi.decode(
            paymasterAndData[VALID_TIMESTAMP_OFFSET:SIGNATURE_OFFSET],
            (uint48, uint48)
        );
        signature = paymasterAndData[SIGNATURE_OFFSET:];
    }

    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) internal override {
        if (mode == PostOpMode.postOpReverted || metaPaymaster == address(0)) {
            return;
        }
        (uint256 maxFeePerGas, uint256 maxPriorityFeePerGas) = abi.decode(
            context,
            (uint256, uint256)
        );
        uint256 gasPrice = _getGasPrice(maxFeePerGas, maxPriorityFeePerGas);
        IMetaPaymaster(metaPaymaster).fund(
            address(this),
            actualGasCost + POST_OP_OVERHEAD * gasPrice
        );
    }

    /*//////////////////////////////////////////////////////////////
                            OWNER ONLY
    //////////////////////////////////////////////////////////////*/

    function setMetaPaymaster(address _metaPaymaster) external onlyOwner {
        metaPaymaster = _metaPaymaster;
    }

    function setVerifyingSigner(address _verifyingSigner) external onlyOwner {
        verifyingSigner = _verifyingSigner;
    }

    /*//////////////////////////////////////////////////////////////
                            FALLBACK
    //////////////////////////////////////////////////////////////*/

    receive() external payable {
        // use address(this).balance rather than msg.value in case of force-send
        (bool callSuccess, ) = payable(address(entryPoint)).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Deposit failed");
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE
    //////////////////////////////////////////////////////////////*/

    function _getGasPrice(
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas
    ) private view returns (uint256) {
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return maxFeePerGas;
        }
        return _min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
