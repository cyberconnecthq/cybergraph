// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "kernel/src/Kernel.sol";
import { EIP1967Proxy } from "kernel/src/factory/EIP1967Proxy.sol";

/**
 * @title ICyberAccountFactory
 * @author CyberConnect
 */
interface ICyberAccountFactory {
    function createAccount(
        IKernelValidator _validator,
        bytes calldata _data,
        uint256 _index
    ) external returns (EIP1967Proxy proxy);

    function getAccountAddress(
        IKernelValidator _validator,
        bytes calldata _data,
        uint256 _index
    ) external view returns (address);

    function addStake(uint32 _unstakeDelaySec) external payable;

    function unlockStake() external;

    function withdrawStake() external;
}
