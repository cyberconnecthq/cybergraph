// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Vm.sol";
import "kernel/src/Kernel.sol";
import "forge-std/console.sol";

import { IDeployer } from "../../src/interfaces/IDeployer.sol";
import { ISoul } from "../../src/interfaces/ISoul.sol";
import { ISubscribeDeployer } from "../../src/interfaces/ISubscribeDeployer.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { Clones } from "openzeppelin-contracts/contracts/proxy/Clones.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { TimelockController } from "openzeppelin-contracts/contracts/governance/TimelockController.sol";
import { ECDSAValidator } from "kernel/src/validator/ECDSAValidator.sol";
import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { CyberAccountFactory } from "../../src/factory/CyberAccountFactory.sol";
import { Soul } from "../../src/core/Soul.sol";
import { MiddlewareManager } from "../../src/core/MiddlewareManager.sol";
import { Content } from "../../src/core/Content.sol";
import { Essence } from "../../src/core/Essence.sol";
import { W3st } from "../../src/core/W3st.sol";
import { Subscribe } from "../../src/core/Subscribe.sol";
import { TokenReceiver } from "../../src/periphery/TokenReceiver.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { DeploySetting } from "./DeploySetting.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { Create2Deployer } from "../../src/deployer/Create2Deployer.sol";
import { Deployer } from "../../src/deployer/Deployer.sol";
import { SubscribeDeployer } from "../../src/deployer/SubscribeDeployer.sol";
import { Treasury } from "../../src/middlewares/base/Treasury.sol";
import { PermissionMw } from "../../src/middlewares/PermissionMw.sol";

library LibDeploy {
    // create2 deploy all contract with this protocol salt
    bytes32 constant SALT = keccak256(bytes("CCV3"));

    string internal constant OUTPUT_FILE = "docs/deploy/";

    function _fileName() internal view returns (string memory) {
        uint256 chainId = block.chainid;
        string memory chainName;
        if (chainId == 1) chainName = "mainnet";
        else if (chainId == 80001) chainName = "mumbai";
        else if (chainId == 137) chainName = "polygon";
        else if (chainId == 420) chainName = "op_goerli";
        else if (chainId == 84531) chainName = "base_goerli";
        else if (chainId == 59140) chainName = "linea_goerli";
        else if (chainId == 534353) chainName = "scroll_alpha";
        else if (chainId == 59144) chainName = "linea";
        else if (chainId == 56) chainName = "bnb";
        else if (chainId == 10) chainName = "op";
        else if (chainId == 97) chainName = "bnbt";
        else if (chainId == 8453) chainName = "base";
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

    function deployMw(
        Vm vm,
        address _dc,
        address engine,
        address mwManager
    ) internal returns (address permissionMw) {
        Create2Deployer dc = Create2Deployer(_dc);
        permissionMw = dc.deploy(
            abi.encodePacked(
                type(PermissionMw).creationCode,
                abi.encode(engine)
            ),
            SALT
        );
        _write(vm, "PermissionMw", permissionMw);
    }

    function deployValidator(Vm vm, address _dc) internal {
        Create2Deployer dc = Create2Deployer(_dc);
        address validator = dc.deploy(
            abi.encodePacked(type(ECDSAValidator).creationCode),
            SALT
        );
        _write(vm, "ECDSAValidator", validator);
    }

    function setSoulMinter(
        Vm,
        address soul,
        address target,
        bool isMinter
    ) internal {
        ISoul(soul).setMinter(target, isMinter);
        require(ISoul(soul).isMinter(target) == isMinter, "NOT_CORRECT_MINTER");
    }

    function deployFactory(
        Vm vm,
        address _dc,
        address entryPoint,
        address soul,
        address factoryOwner,
        bool writeFile
    ) internal returns (address factory) {
        Create2Deployer dc = Create2Deployer(_dc);
        IEntryPoint iep = IEntryPoint(entryPoint);
        factory = dc.deploy(
            abi.encodePacked(
                type(CyberAccountFactory).creationCode,
                abi.encode(iep, soul, factoryOwner)
            ),
            SALT
        );

        if (writeFile) {
            _write(vm, "CyberAccount Factory", factory);
        }
    }

    struct ContractAddresses {
        address soul;
        address manager;
        address engine;
        address engineImpl;
        address deployer;
        address subscribeDeployer;
        address deployedEssImpl;
        address deployedContentImpl;
        address deployedW3stImpl;
        address deployedSubImpl;
        address cyberTreasury;
        address cyberFactory;
        address calculatedEssImpl;
        address calculatedContentImpl;
        address calculatedW3stImpl;
        address calculatedSubImpl;
    }

    function deployAll(
        Vm vm,
        address _dc,
        address protocolOwner,
        address treasuryReceiver,
        address soulManager,
        address entryPoint,
        address backendSigner,
        bool writeFile
    ) internal {
        // sending from deployer
        ContractAddresses memory contractAddresses = deployGraph(
            vm,
            _dc,
            protocolOwner,
            treasuryReceiver,
            soulManager,
            writeFile
        );

        address permissionMw = deployMw(
            vm,
            _dc,
            contractAddresses.engine,
            contractAddresses.manager
        );
        deployValidator(vm, _dc);
        address factory = deployFactory(
            vm,
            _dc,
            entryPoint,
            contractAddresses.soul,
            protocolOwner,
            writeFile
        );
        deployReceiver(vm, _dc, protocolOwner, writeFile);

        // sending from protocol owner
        // MiddlewareManager(mwManager).allowMw(permissionMw, true);
        // setSoulMinter(vm, contractAddresses.soul, factory, true);
        // setSoulMinter(vm, contractAddresses.soul, backendSigner, true);
        // CyberAccountFactory(factory).addStake{ value: 0.002 ether }(1 days);
    }

    function setInitialState(
        Vm vm,
        address _dc,
        address mwManager,
        address permissionMw,
        address soul,
        address factory,
        address backendSigner
    ) internal {
        // sending from protocol owner
        MiddlewareManager(mwManager).allowMw(permissionMw, true);
        setSoulMinter(vm, soul, factory, true);
        setSoulMinter(vm, soul, backendSigner, true);
        CyberAccountFactory(factory).addStake{ value: 0.01 ether }(1 days);
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
        addrs.soul = dc.deploy(
            abi.encodePacked(
                type(Soul).creationCode,
                abi.encode(soulManager, "CyberSoul", "SOUL")
            ),
            SALT
        );

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

        addrs.subscribeDeployer = dc.deploy(
            abi.encodePacked(type(SubscribeDeployer).creationCode),
            SALT
        );

        addrs.calculatedEssImpl = _computeAddress(
            abi.encodePacked(type(Essence).creationCode),
            SALT,
            addrs.deployer
        );

        addrs.calculatedContentImpl = _computeAddress(
            abi.encodePacked(type(Content).creationCode),
            SALT,
            addrs.deployer
        );

        addrs.calculatedW3stImpl = _computeAddress(
            abi.encodePacked(type(W3st).creationCode),
            SALT,
            addrs.deployer
        );

        addrs.calculatedSubImpl = _computeAddress(
            abi.encodePacked(type(Subscribe).creationCode),
            SALT,
            addrs.subscribeDeployer
        );

        // 4. deploy engine
        addrs.engineImpl = dc.deploy(type(CyberEngine).creationCode, SALT);
        addrs.engine = dc.deploy(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    addrs.engineImpl,
                    abi.encodeWithSelector(
                        CyberEngine.initialize.selector,
                        DataTypes.InitParams(
                            addrs.soul,
                            addrs.manager,
                            addrs.calculatedEssImpl,
                            addrs.calculatedContentImpl,
                            addrs.calculatedW3stImpl,
                            addrs.calculatedSubImpl,
                            protocolOwner
                        )
                    )
                )
            ),
            SALT
        );

        // 5. deploy ess,content and w3st
        addrs.deployedEssImpl = IDeployer(addrs.deployer).deployEssence(
            SALT,
            addrs.engine
        );
        require(
            addrs.deployedEssImpl == addrs.calculatedEssImpl,
            "WRONG_ESS_ADDR"
        );

        addrs.deployedContentImpl = IDeployer(addrs.deployer).deployContent(
            SALT,
            addrs.engine
        );
        require(
            addrs.deployedContentImpl == addrs.calculatedContentImpl,
            "WRONG_CONTENT_ADDR"
        );

        addrs.deployedW3stImpl = IDeployer(addrs.deployer).deployW3st(
            SALT,
            addrs.engine
        );
        require(
            addrs.deployedW3stImpl == addrs.calculatedW3stImpl,
            "WRONG_W3ST_ADDR"
        );

        addrs.deployedSubImpl = ISubscribeDeployer(addrs.subscribeDeployer)
            .deploySubscribe(SALT, addrs.engine);
        require(
            addrs.deployedSubImpl == addrs.calculatedSubImpl,
            "WRONG_SUB_ADDR"
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
            _write(vm, "SubscribeDeployer", addrs.subscribeDeployer);
            _write(vm, "CyberEngineImpl", addrs.engineImpl);
            _write(vm, "CyberEngine", addrs.engine);
            _write(vm, "Essence", addrs.deployedEssImpl);
            _write(vm, "Content", addrs.deployedContentImpl);
            _write(vm, "W3ST", addrs.deployedW3stImpl);
            _write(vm, "Subscribe", addrs.deployedSubImpl);
            _write(vm, "Treasury", addrs.cyberTreasury);
        }
    }

    function deployReceiver(
        Vm vm,
        address _dc,
        address protocolOwner,
        bool writeFile
    ) internal {
        Create2Deployer dc = Create2Deployer(_dc);
        address tr = dc.deploy(
            abi.encodePacked(
                type(TokenReceiver).creationCode,
                abi.encode(protocolOwner)
            ),
            SALT
        );

        if (writeFile) {
            _write(vm, "TokenReceiver", tr);
        }
    }

    function deployTimeLock(
        Vm vm,
        address ownerSafe,
        uint256 minDeplay,
        bool writeFile
    ) internal returns (address lock) {
        require(ownerSafe != address(0), "WRONG_OWNER");

        address[] memory proposers = new address[](1);
        proposers[0] = ownerSafe;
        address[] memory executors = new address[](1);
        executors[0] = ownerSafe;

        lock = address(
            new TimelockController(minDeplay, proposers, executors, ownerSafe)
        );
        if (writeFile) {
            _write(vm, "Timelock", lock);
        }
    }

    function changeOwnership(
        Vm vm,
        address timelock,
        address receiver
    ) internal {
        // Receiver owner role change to timelock
        TokenReceiver(receiver).transferOwnership(timelock);
        require(
            TokenReceiver(receiver).owner() == timelock,
            "WRONG_RECEIVER_OWNER"
        );
    }

    function deployInTest(
        Vm vm,
        address protocolOwner,
        address treasuryReceiver,
        address entryPoint
    ) internal returns (ContractAddresses memory addrs) {
        Create2Deployer dc = new Create2Deployer();
        addrs = deployGraph(
            vm,
            address(dc),
            protocolOwner,
            treasuryReceiver,
            address(this),
            false
        );
        addrs.cyberFactory = deployFactory(
            vm,
            address(dc),
            entryPoint,
            addrs.soul,
            protocolOwner,
            false
        );
    }
}
