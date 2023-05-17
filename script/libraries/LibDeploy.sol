// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Vm.sol";
import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

import { CyberAccountFactory } from "../../src/factory/CyberAccountFactory.sol";
import { DeploySetting } from "./DeploySetting.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { Create2Deployer } from "../../src/deployer/Create2Deployer.sol";

library LibDeploy {
    // create2 deploy all contract with this protocol salt
    bytes32 constant SALT = keccak256(bytes("CyberAccount"));

    string internal constant OUTPUT_FILE = "docs/deploy/";

    function _fileName() internal view returns (string memory) {
        uint256 chainId = block.chainid;
        string memory chainName;
        if (chainId == 1) chainName = "mainnet";
        else if (chainId == 80001) chainName = "mumbai";
        else if (chainId == 137) chainName = "polygon";
        else chainName = "unknown";
        return
            string(
                abi.encodePacked(
                    OUTPUT_FILE,
                    string(
                        abi.encodePacked(
                            chainName,
                            "-",
                            LibString.toString(chainId)
                        )
                    ),
                    "/contract"
                )
            );
    }

    function _fileNameMd() internal view returns (string memory) {
        return string(abi.encodePacked(_fileName(), ".md"));
    }

    function _writeText(
        Vm vm,
        string memory fileName,
        string memory text
    ) internal {
        vm.writeLine(fileName, text);
    }

    function _writeHelper(Vm vm, string memory name, address addr) internal {
        _writeText(
            vm,
            _fileNameMd(),
            string(
                abi.encodePacked(
                    "|",
                    name,
                    "|",
                    LibString.toHexString(addr),
                    "|"
                )
            )
        );
    }

    function _write(Vm vm, string memory name, address addr) internal {
        _writeHelper(vm, name, addr);
    }

    function deployFactory(
        Vm vm,
        address entryPoint
    ) internal returns (address factory) {
        //Create2Deployer dc = Create2Deployer(params.deployerContract);
        IEntryPoint iep = IEntryPoint(entryPoint);
        // factory = dc.deploy(
        //     abi.encodePacked(
        //         type(CyberWalletFactory).creationCode,
        //         abi.encode(iep)
        //     ),
        //     SALT
        // );
        factory = address(new CyberAccountFactory(iep));

        _write(vm, "CyberAccount Factory", factory);
    }
}
