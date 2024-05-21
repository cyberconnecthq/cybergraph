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
import { LimitedOnlyOnceMw } from "../../src/middlewares/LimitedOnlyOnceMw.sol";
import { SpecialReward } from "../../src/periphery/SpecialReward.sol";
import { CyberVault } from "../../src/periphery/CyberVault.sol";
import { LaunchTokenPool } from "../../src/periphery/LaunchTokenPool.sol";
import { CyberStakingPool } from "../../src/periphery/CyberStakingPool.sol";
import { CyberVaultV2 } from "../../src/periphery/CyberVaultV2.sol";
import { CyberVaultV3 } from "../../src/periphery/CyberVaultV3.sol";
import { WorkInCryptoNFT } from "../../src/periphery/WorkInCryptoNFT.sol";
import { GasBridge } from "../../src/periphery/GasBridge.sol";
import { CyberNewEraGate } from "../../src/periphery/CyberNewEraGate.sol";
import { CyberNewEra } from "../../src/periphery/CyberNewEra.sol";
import { CyberRelayer } from "../../src/periphery/CyberRelayer.sol";
import { CyberPaymaster } from "../../src/paymaster/CyberPaymaster.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { CyberFrog } from "../../src/periphery/CyberFrog.sol";

library LibDeploy {
    // create2 deploy all contract with this protocol salt
    bytes32 constant SALT = keccak256(bytes("CCV3"));

    string internal constant OUTPUT_FILE = "docs/deploy/";

    address constant EXPECTED_MULTICALL_ADDRESS =
        0x8ae01fCF7c655655fF2c6Ef907b8B4718Ab4e17c;
    address constant DETERMINISTIC_DEPLOYER =
        0x4e59b44847b379578588920cA78FbF26c0B4956C;

    function _fileName() internal view returns (string memory) {
        uint256 chainId = block.chainid;
        string memory chainName;
        if (chainId == 1) chainName = "eth";
        else if (chainId == 80001) chainName = "mumbai";
        else if (chainId == 137) chainName = "polygon";
        else if (chainId == 420) chainName = "op_goerli";
        else if (chainId == 84531) chainName = "base_goerli";
        else if (chainId == 59140) chainName = "linea_goerli";
        else if (chainId == 534351) chainName = "scroll_sepolia";
        else if (chainId == 59144) chainName = "linea";
        else if (chainId == 56) chainName = "bnb";
        else if (chainId == 10) chainName = "op";
        else if (chainId == 42161) chainName = "arbitrum";
        else if (chainId == 421613) chainName = "arbitrum_goerli";
        else if (chainId == 97) chainName = "bnbt";
        else if (chainId == 8453) chainName = "base";
        else if (chainId == 5611) chainName = "opbnbt";
        else if (chainId == 204) chainName = "opbnb";
        else if (chainId == 534352) chainName = "scroll";
        else if (chainId == 11155111) chainName = "sepolia";
        else if (chainId == 5000) chainName = "mantle";
        else if (chainId == 5001) chainName = "mantle_testnet";
        else if (chainId == 168587773) chainName = "blast_sepolia";
        else if (chainId == 11155420) chainName = "op_sepolia";
        else if (chainId == 84532) chainName = "base_sepolia";
        else if (chainId == 81457) chainName = "blast";
        else if (chainId == 111557560) chainName = "cyber_testnet";
        else if (chainId == 80002) chainName = "amoy";
        else if (chainId == 13473) chainName = "imx_testnet";
        else if (chainId == 7560) chainName = "cyber";
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

    function deployMultiSend() internal {
        if (EXPECTED_MULTICALL_ADDRESS.code.length == 0) {
            (bool success, bytes memory ret) = DETERMINISTIC_DEPLOYER.call(
                hex"000000000000000000000000000000000000000000000000000000000000000060a060405234801561001057600080fd5b50306080526080516102bd61002f6000396000604f01526102bd6000f3fe60806040526004361061001e5760003560e01c80638d80ff0a14610023575b600080fd5b6100366100313660046101b8565b610038565b005b73ffffffffffffffffffffffffffffffffffffffff7f0000000000000000000000000000000000000000000000000000000000000000163003610101576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152603060248201527f4d756c746953656e642073686f756c64206f6e6c792062652063616c6c65642060448201527f7669612064656c656761746563616c6c00000000000000000000000000000000606482015260840160405180910390fd5b805160205b81811015610184578083015160f81c6001820184015160601c60158301850151603584018601516055850187016000856000811461014b576001811461015b57610166565b6000808585888a5af19150610166565b6000808585895af491505b508061017157600080fd5b5050806055018501945050505050610106565b505050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b6000602082840312156101ca57600080fd5b813567ffffffffffffffff808211156101e257600080fd5b818401915084601f8301126101f657600080fd5b81358181111561020857610208610189565b604051601f82017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0908116603f0116810190838211818310171561024e5761024e610189565b8160405282815287602084870101111561026757600080fd5b82602086016020830137600092810160200192909252509594505050505056fea2646970667358221220aee0f2dd047c52784b9c7806e4078197141e146ec66587d8610576db5f8ad20e64736f6c634300080f0033"
            );
        } else {
            console.log("multisend address: %s", EXPECTED_MULTICALL_ADDRESS);
        }
    }

    function deployLimitedOnlyOnceMw(
        Vm vm,
        address _dc,
        address engine,
        address mwManager
    ) internal returns (address mw) {
        Create2Deployer dc = Create2Deployer(_dc);
        mw = dc.deploy(
            abi.encodePacked(
                type(LimitedOnlyOnceMw).creationCode,
                abi.encode(engine)
            ),
            SALT
        );
        _write(vm, "LimitedOnlyOnceMw", mw);
        MiddlewareManager(mwManager).allowMw(mw, true);
    }

    function deploySpecialReward(
        Vm vm,
        address owner,
        string memory tokenURI,
        string memory contractName
    ) internal {
        address sr = address(new SpecialReward(owner, tokenURI));
        _writeHelper(vm, contractName, sr);
    }

    function deployPermissionMw(
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

        deployPermissionMw(
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
        deployMultiSend();
        deployPaymaster(vm, _dc, entryPoint, protocolOwner, backendSigner);
    }

    function setInitialState(
        Vm vm,
        address _dc,
        address mwManager,
        address permissionMw,
        address soul,
        address factory,
        address cyberpaymaster,
        address backendSigner
    ) internal {
        // sending from protocol owner
        MiddlewareManager(mwManager).allowMw(permissionMw, true);
        setSoulMinter(vm, soul, factory, true);
        setSoulMinter(vm, soul, backendSigner, true);
        // CyberAccountFactory(factory).addStake{ value: 0.1 ether }(1 days);
        CyberPaymaster(payable(cyberpaymaster)).setVerifyingSigner(
            backendSigner
        );
        // CyberPaymaster(payable(paymaster)).addStake{ value: 10 ether }(1 days);
    }

    function deployPaymaster(
        Vm vm,
        address _dc,
        address entryPoint,
        address owner,
        address signer
    ) internal {
        Create2Deployer dc = Create2Deployer(_dc);
        address paymaster = dc.deploy(
            abi.encodePacked(
                type(CyberPaymaster).creationCode,
                abi.encode(entryPoint, owner)
            ),
            SALT
        );
        _write(vm, "CyberPaymaster", paymaster);
    }

    function deployLaunchTokenPool(
        Vm vm,
        address _dc,
        address owner,
        address cyber
    ) internal {
        Create2Deployer dc = Create2Deployer(_dc);
        address launchTokenPool = dc.deploy(
            abi.encodePacked(
                type(LaunchTokenPool).creationCode,
                abi.encode(owner, cyber)
            ),
            SALT
        );

        _write(vm, "LaunchTokenPool", launchTokenPool);
    }

    function deployStakingPool(
        Vm vm,
        address _dc,
        address weth,
        address owner
    ) internal {
        Create2Deployer dc = Create2Deployer(_dc);
        address stakingPool = dc.deploy(
            abi.encodePacked(
                type(CyberStakingPool).creationCode,
                abi.encode(weth, owner)
            ),
            SALT
        );

        _write(vm, "CyberStakingPool", stakingPool);
    }

    function deployGasBridge(Vm vm, address _dc, address owner) internal {
        Create2Deployer dc = Create2Deployer(_dc);
        address gasBridge = dc.deploy(
            abi.encodePacked(type(GasBridge).creationCode, abi.encode(owner)),
            SALT
        );

        _write(vm, "GasBridge", gasBridge);
    }

    function deployCyberRelayer(
        Vm vm,
        address _dc,
        address owner,
        address backendSigner
    ) internal {
        Create2Deployer dc = Create2Deployer(_dc);
        address cyberRelayer = dc.deploy(
            abi.encodePacked(
                type(CyberRelayer).creationCode,
                abi.encode(owner)
            ),
            SALT
        );

        CyberRelayer(cyberRelayer).grantRole(
            keccak256("RELAYER_ROLE"),
            backendSigner
        );

        _write(vm, "CyberRelayer", cyberRelayer);
    }

    function deployCyberNewEraGate(
        Vm vm,
        address _dc,
        address owner,
        uint256 mintFee
    ) internal {
        Create2Deployer dc = Create2Deployer(_dc);
        address CyberNewEraGate = dc.deploy(
            abi.encodePacked(
                type(CyberNewEraGate).creationCode,
                abi.encode(owner, mintFee)
            ),
            SALT
        );

        _write(vm, "CyberNewEraGate", CyberNewEraGate);
    }

    function deployCyberNewEra(
        Vm vm,
        address _dc,
        address owner,
        address signer,
        string memory baseUri
    ) internal {
        Create2Deployer dc = Create2Deployer(_dc);
        address CyberNewEra = dc.deploy(
            abi.encodePacked(
                type(CyberNewEra).creationCode,
                abi.encode(baseUri, owner, signer)
            ),
            SALT
        );

        _write(vm, "CyberNewEra", CyberNewEra);
    }

    function upgradeVault(Vm vm, address _dc, address vaultProxy) internal {
        Create2Deployer dc = Create2Deployer(_dc);
        address cyberVaultV3Impl = dc.deploy(
            type(CyberVaultV3).creationCode,
            SALT
        );
        _write(vm, "CyberVaultV3(Impl)", cyberVaultV3Impl);

        UUPSUpgradeable(vaultProxy).upgradeTo(cyberVaultV3Impl);

        address[] memory wl = new address[](2);
        wl[0] = address(0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85);
        wl[1] = address(0x4200000000000000000000000000000000000006);
        bool[] memory wlStatus = new bool[](2);
        wlStatus[0] = true;
        wlStatus[1] = true;

        CyberVaultV3(vaultProxy).setV3Variables(
            address(0xCb1355ff08Ab38bBCE60111F1bb2B784bE25D7e8),
            address(0x4200000000000000000000000000000000000006),
            address(0x94b008aA00579c1307B0EF2c499aD98a8ce58e58),
            wl,
            wlStatus
        );
    }

    function deployVault(
        Vm vm,
        address _dc,
        address owner,
        address recipient,
        address operator,
        address uniswap,
        address wrappedNativeCurrency,
        address tokenOut,
        address[] memory tokenInList,
        bool[] memory tokenInApproved
    ) internal {
        Create2Deployer dc = Create2Deployer(_dc);

        address cyberVaultImpl = dc.deploy(
            type(CyberVaultV3).creationCode,
            SALT
        );

        _write(vm, "CyberVault(Impl)", cyberVaultImpl);

        address cyberVaultProxy = dc.deploy(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    cyberVaultImpl,
                    abi.encodeWithSelector(
                        CyberVault.initialize.selector,
                        owner,
                        recipient
                    )
                )
            ),
            SALT
        );

        _write(vm, "CyberVault(Proxy)", cyberVaultProxy);

        CyberVaultV3(cyberVaultProxy).grantRole(
            keccak256(bytes("OPERATOR_ROLE")),
            operator
        );

        CyberVaultV3(cyberVaultProxy).setV3Variables(
            uniswap,
            wrappedNativeCurrency,
            tokenOut,
            tokenInList,
            tokenInApproved
        );
    }

    function deployWorkInCryptoNFT(
        Vm vm,
        address _dc,
        string memory name,
        string memory symbol,
        string memory uri,
        address protocolOwner,
        address signer,
        bool writeFile
    ) internal {
        Create2Deployer dc = Create2Deployer(_dc);
        address tr = dc.deploy(
            abi.encodePacked(
                type(WorkInCryptoNFT).creationCode,
                abi.encode(name, symbol, uri, protocolOwner, signer)
            ),
            SALT
        );

        if (writeFile) {
            _write(vm, "WorkInCryptoNFT", tr);
        }
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
            _write(vm, "Timelock(V2)", lock);
        }
    }

    function deployFrog(Vm vm) internal returns (address frog) {
        // frog = address(
        //     new CyberFrog("https://remote-image.decentralized-content.com/image?url=https%3A%2F%2Fmagic.decentralized-content.com%2Fipfs%2Fbafkreihs6j3o5g7rab7yt5ml2xukkfsl2f2yeopyoskebozw7u5fiuuoiq&w=1920&q=75")
        // );
        // CyberFrog(address(0xFE98bA9D562F8359981269c9E22fDBf02717b723)).mint(address(0x8ddD03b89116ba89E28Ef703fe037fF77451e38E), 1, 1, "");
        //_write(vm, "CyberFrog", frog);
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

    function withdraw(
        Vm vm,
        address timelock,
        address receiver,
        address to
    ) internal {
        // string memory hexData = "0xf3fef3a3000000000000000000000000ad09648a3b2e725d606c6440ef3d1fb9693bac1b00000000000000000000000000000000000000000000000000005af3107a4000"; prev

        // string memory hexData = "0xf3fef3a30000000000000000000000007884f7f04f994da14302a16cf15e597e31eebecf0000000000000000000000000000000000000000000000019274b259f6540000";
        // bytes memory b = abi.encodePacked(hexData);

        bytes
            memory b = hex"f3fef3a30000000000000000000000007884f7f04f994da14302a16cf15e597e31eebecf0000000000000000000000000000000000000000000000019274b259f6540000";
        // TimelockController(payable(timelock)).schedule(
        //     receiver,
        //     0,
        //     b,
        //     0x0000000000000000000000000000000000000000000000000000000000000000,
        //     0x0000000000000000000000000000000000000000000000000000000000000000,
        //     48 * 3600 + 1
        // );

        TimelockController(payable(timelock)).execute(
            receiver,
            0,
            b,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000000000000000000000000000
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
