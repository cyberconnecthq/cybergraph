// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

import { BaseWallet } from "../base/BaseWallet.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

contract CyberWallet is UUPSUpgradeable, Initializable, BaseWallet {
    IEntryPoint private immutable _entryPoint;

    function entryPoint() public view virtual returns (IEntryPoint) {
        return _entryPoint;
    }

    uint256 public nonce;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
    }

    function initialize(address _owner) external virtual initializer {
        BaseWallet.__BaseWallet_Init(_owner);
    }

    function execTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) public virtual {
        require(msg.sender == address(entryPoint()), "CW_NOT_FROM_ENTRYPOINT");
        execute(to, value, data, gasleft());
    }

    function validateUserOp(
        DataTypes.UserOperation calldata userOp,
        bytes32 userOpHash,
        address,
        uint256 missingAccountFunds
    ) external returns (uint256) {
        if (nonce != 0) {
            require(
                msg.sender == address(entryPoint()),
                "CW_NOT_FROM_ENTRYPOINT"
            );
            require(
                _checkSignature(userOpHash, userOp.signature),
                "WRONG_SIGNATURE"
            );

            if (userOp.initCode.length == 0) {
                require(nonce == userOp.nonce, "account: invalid nonce");
            }
            ++nonce;
        }
        if (missingAccountFunds > 0) {
            (bool success, ) = payable(msg.sender).call{
                value: missingAccountFunds
            }("");
            (success);
            //ignore failure (its EntryPoint's job to verify, not account.)
        }
        return 0; //always return 0 as this function doesn't support time based validation
    }

    // TODO: auth
    // function replaceEntrypoint(address newEntrypoint) public {
    //     entryPoint = newEntrypoint;
    // }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override {
        (newImplementation);
        require(msg.sender == owner, "ONLY_OWNER");
    }
}
