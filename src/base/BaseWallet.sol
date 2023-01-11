// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

import { IWallet } from "../interfaces/IWallet.sol";
import { IERC1271 } from "../interfaces/IERC1271.sol";

import { SignatureValidator } from "../libraries/SignatureValidator.sol";

import { Executor } from "./Executor.sol";

contract BaseWallet is Executor, IWallet, IERC1271 {
    bytes4 private constant SELECTOR_ERC1271_BYTES32_BYTES = 0x1626ba7e;

    address public owner;
    address public guardianModule;

    constructor(address _owner, address _guardianModule) {
        require(_owner != address(0), "BW_ZERO_ADDRESS");

        owner = _owner;
        guardianModule = _guardianModule;
    }

    modifier onlyOwnerOrGuardian() {
        require(
            msg.sender == owner || msg.sender == guardianModule,
            "BW_NOT_AUTHORIZED"
        );
        _;
    }

    function setOwner(address _newOwner) external override onlyOwnerOrGuardian {
        require(_newOwner != address(0), "BW_ZERO_ADDRESS");
        owner = _newOwner;

        emit SetOwner(_newOwner);
    }

    function setGuardianModule(
        address _newGuardianModule
    ) external override onlyOwnerOrGuardian {
        require(_newGuardianModule != address(0), "BW_ZERO_ADDRESS");
        guardianModule = _newGuardianModule;

        emit SetGuardianModule(_newGuardianModule);
    }

    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view override returns (bytes4) {
        if (_checkSignature(_hash, _signature)) {
            return SELECTOR_ERC1271_BYTES32_BYTES;
        } else {
            return 0xffffffff;
        }
    }

    function _checkSignature(
        bytes32 _hash,
        bytes memory _signature
    ) internal view returns (bool) {
        return SignatureValidator.recoverSigner(_hash, _signature) == owner;
    }
}
