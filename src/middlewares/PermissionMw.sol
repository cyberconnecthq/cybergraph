// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IMiddleware } from "../interfaces/IMiddleware.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

import { EIP712 } from "../base/EIP712.sol";
import { OnlyEngineMw } from "./base/OnlyEngineMw.sol";

/**
 * @title Permission Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to allow an address to collect only if they have a valid signiture from the owner
 */
contract PermissionMw is IMiddleware, EIP712, OnlyEngineMw {
    /*//////////////////////////////////////////////////////////////
                                EVENT
    //////////////////////////////////////////////////////////////*/

    event PermissionMwSet(
        address indexed account,
        DataTypes.Category indexed category,
        uint256 indexed id,
        address signer
    );

    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    struct MiddlewareData {
        address signer;
        mapping(address => uint256) nonces;
    }

    bytes32 public constant COLLECT_TYPEHASH =
        keccak256(
            "collect(address collector,address account,uint8 category,uint256 id,uint256 amount,uint256 nonce,uint256 deadline)"
        );

    mapping(address => mapping(DataTypes.Category => mapping(uint256 => MiddlewareData)))
        internal _signerStorage;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address engine) OnlyEngineMw(engine) {}

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMiddleware
    function setMwData(
        address account,
        DataTypes.Category category,
        uint256 id,
        bytes calldata data
    ) external override onlyEngine {
        address signer = abi.decode(data, (address));
        require(signer != address(0), "INVALID_SIGNER");
        _signerStorage[account][category][id].signer = signer;

        emit PermissionMwSet(account, category, id, signer);
    }

    /**
     * @inheritdoc IMiddleware
     * @notice Process that checks if the collector has the correct signature from the signer
     */
    function preProcess(
        DataTypes.MwParams calldata params
    ) external override onlyEngine {
        DataTypes.EIP712Signature memory sig;

        (sig.v, sig.r, sig.s, sig.deadline) = abi.decode(
            params.data,
            (uint8, bytes32, bytes32, uint256)
        );

        MiddlewareData storage mwData = _signerStorage[params.account][
            params.category
        ][params.id];

        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        COLLECT_TYPEHASH,
                        params.to,
                        params.account,
                        params.category,
                        params.id,
                        params.amount,
                        mwData.nonces[params.to]++,
                        sig.deadline
                    )
                )
            ),
            mwData.signer,
            sig.v,
            sig.r,
            sig.s,
            sig.deadline
        );
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the nonce of the address.
     *
     * @param account The account address.
     * @param category The category of target NFT.
     * @param id The corresponding identifier for a specific category.
     * @param collector The collector address.
     * @return uint256 The nonce.
     */
    function getNonce(
        address account,
        DataTypes.Category category,
        uint256 id,
        address collector
    ) external view returns (uint256) {
        return _signerStorage[account][category][id].nonces[collector];
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _domainSeparatorName()
        internal
        pure
        override
        returns (string memory)
    {
        return "PermissionMw";
    }
}
