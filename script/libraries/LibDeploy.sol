// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Vm.sol";
import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { IDeployer } from "../../src/interfaces/IDeployer.sol";
import { Clones } from "openzeppelin-contracts/contracts/proxy/Clones.sol";

import { CyberAccountFactory } from "../../src/factory/CyberAccountFactory.sol";
import { Soul } from "../../src/core/Soul.sol";
import { MiddlewareManager } from "../../src/core/MiddlewareManager.sol";
import { Content } from "../../src/core/Content.sol";
import { Essence } from "../../src/core/Essence.sol";
import { W3st } from "../../src/core/W3st.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { DeploySetting } from "./DeploySetting.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { Create2Deployer } from "../../src/deployer/Create2Deployer.sol";
import { Deployer } from "../../src/deployer/Deployer.sol";
import { Treasury } from "../../src/middlewares/base/Treasury.sol";

library LibDeploy {
    // create2 deploy all contract with this protocol salt
    bytes32 constant SALT = keccak256(bytes("Test5"));

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

    function _computeAddress(
        bytes memory _byteCode,
        bytes32 _salt,
        address deployer
    ) internal pure returns (address) {
        bytes32 hash_ = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                deployer,
                _salt,
                keccak256(_byteCode)
            )
        );
        return address(uint160(uint256(hash_)));
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

    struct ContractAddresses {
        address soul;
        address manager;
        address engine;
        address deployer;
        address deployedEssImpl;
        address deployedContentImpl;
        address deployedW3stImpl;
        address cyberTreasury;
    }

    function deployGraph(
        Vm vm,
        address _dc,
        address protocolOwner,
        address treasuryReceiver,
        address soulManager,
        bool writeFile
    ) internal returns (ContractAddresses memory addrs) {
        Create2Deployer dc = Create2Deployer(_dc);

        // 1. deploy soul
        address soulImpl = dc.deploy(
            abi.encodePacked(type(Soul).creationCode),
            SALT
        );
        addrs.soul = Clones.clone(soulImpl);
        Soul(addrs.soul).initialize(soulManager, "CyberSoul", "SOUL");

        // 2. deploy mw manager
        addrs.manager = dc.deploy(
            abi.encodePacked(
                type(MiddlewareManager).creationCode,
                abi.encode(protocolOwner)
            ),
            SALT
        );

        // 3. pre-compute ess,content,w3st addresses
        addrs.deployer = dc.deploy(
            abi.encodePacked(type(Deployer).creationCode),
            SALT
        );

        address calculatedEssImpl = _computeAddress(
            abi.encodePacked(type(Essence).creationCode),
            SALT,
            addrs.deployer
        );

        address calculatedContentImpl = _computeAddress(
            abi.encodePacked(type(Content).creationCode),
            SALT,
            addrs.deployer
        );

        address calculatedW3stImpl = _computeAddress(
            abi.encodePacked(type(W3st).creationCode),
            SALT,
            addrs.deployer
        );

        // 4. deploy engine
        addrs.engine = dc.deploy(
            abi.encodePacked(
                type(CyberEngine).creationCode,
                abi.encode(
                    addrs.soul,
                    addrs.manager,
                    calculatedEssImpl,
                    calculatedContentImpl,
                    calculatedW3stImpl
                )
            ),
            SALT
        );

        // 5. deploy ess,content and w3st
        addrs.deployedEssImpl = IDeployer(addrs.deployer).deployEssence(
            SALT,
            addrs.engine
        );
        require(addrs.deployedEssImpl == calculatedEssImpl, "WRONG_ESS_ADDR");

        addrs.deployedContentImpl = IDeployer(addrs.deployer).deployContent(
            SALT,
            addrs.engine
        );
        require(
            addrs.deployedContentImpl == calculatedContentImpl,
            "WRONG_CONTENT_ADDR"
        );

        addrs.deployedW3stImpl = IDeployer(addrs.deployer).deployW3st(
            SALT,
            addrs.engine
        );
        require(
            addrs.deployedW3stImpl == calculatedW3stImpl,
            "WRONG_W3ST_ADDR"
        );

        // 6. deploy treasury
        addrs.cyberTreasury = dc.deploy(
            abi.encodePacked(
                type(Treasury).creationCode,
                abi.encode(protocolOwner, treasuryReceiver, 250)
            ),
            SALT
        );

        if (writeFile) {
            _write(vm, "Soul", addrs.soul);
            _write(vm, "MiddlewareManager", addrs.manager);
            _write(vm, "Deployer", addrs.deployer);
            _write(vm, "CyberEngine", addrs.manager);
            _write(vm, "Essence", addrs.deployedEssImpl);
            _write(vm, "Content", addrs.deployedContentImpl);
            _write(vm, "W3ST", addrs.deployedW3stImpl);
            _write(vm, "Treasury", addrs.cyberTreasury);
        }
    }

    function deployInTest(
        Vm vm,
        address protocolOwner,
        address treasuryReceiver
    ) internal returns (ContractAddresses memory addrs) {
        Create2Deployer dc = new Create2Deployer();
        return
            deployGraph(
                vm,
                address(dc),
                protocolOwner,
                treasuryReceiver,
                address(this),
                false
            );
    }
}
