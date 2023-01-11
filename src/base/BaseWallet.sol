// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

import { IWallet } from "../interfaces/IWallet.sol";

import { Authenticator } from "./Authenticator.sol";
import { Executor } from "./Executor.sol";

contract BaseWallet is Authenticator, Executor, IWallet {
    address public owner;
    address public guardianModule;

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
}
