// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "kernel/src/Kernel.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Create2 } from "openzeppelin-contracts/contracts/utils/Create2.sol";
import { EIP1967Proxy } from "kernel/src/factory/EIP1967Proxy.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import { ICyberAccountFactory } from "../interfaces/ICyberAccountFactory.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";

contract CyberAccountFactoryV2 is
    Ownable,
    ICyberAccountFactory,
    Initializable,
    UUPSUpgradeable
{
    address public cyberAccountFactoryV1;
    IEntryPoint public entryPoint;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IEntryPoint _entryPoint,
        address _cyberAccountFactoryV1,
        address _owner
    ) external initializer {
        entryPoint = _entryPoint;
        cyberAccountFactoryV1 = _cyberAccountFactoryV1;
        _transferOwnership(_owner);
    }

    function createAccount(
        IKernelValidator _validator,
        bytes calldata _data,
        uint256 _index
    ) external override returns (EIP1967Proxy proxy) {
        return
            ICyberAccountFactory(cyberAccountFactoryV1).createAccount(
                _validator,
                _data,
                _index
            );
    }

    function getAccountAddress(
        IKernelValidator _validator,
        bytes calldata _data,
        uint256 _index
    ) public view override returns (address) {
        return
            ICyberAccountFactory(cyberAccountFactoryV1).getAccountAddress(
                _validator,
                _data,
                _index
            );
    }

    function addStake(
        uint32 _unstakeDelaySec
    ) external payable override onlyOwner {
        IEntryPoint(entryPoint).addStake{ value: msg.value }(_unstakeDelaySec);
    }

    function unlockStake() external override onlyOwner {
        IEntryPoint(entryPoint).unlockStake();
    }

    function withdrawStake() external override onlyOwner {
        IEntryPoint(entryPoint).withdrawStake(payable(owner()));
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
