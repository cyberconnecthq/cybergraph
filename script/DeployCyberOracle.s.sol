// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { Create2Deployer } from "../src/deployer/Create2Deployer.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { CyberOracle } from "../src/periphery/CyberOracle.sol";

contract DeployCyberOracle is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        Create2Deployer dc = Create2Deployer(deployParams.deployerContract);

        if (
            block.chainid == DeploySetting.CYBER ||
            block.chainid == DeploySetting.CYBER_TESTNET
        ) {
            address oracleImpl = dc.deploy(
                type(CyberOracle).creationCode,
                LibDeploy.SALT
            );

            LibDeploy._write(vm, "CyberOracle(Impl)", oracleImpl);

            address oracleProxy = dc.deploy(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(
                        oracleImpl,
                        abi.encodeWithSelector(
                            CyberOracle.initialize.selector,
                            deployParams.protocolOwner,
                            8,
                            "Cyber Price Feed"
                        )
                    )
                ),
                LibDeploy.SALT
            );

            LibDeploy._write(vm, "CyberOracle(Proxy)", oracleProxy);

            CyberOracle(oracleProxy).setDataProvider(
                deployParams.backendSigner,
                true
            );
        }
        vm.stopBroadcast();
    }
}
