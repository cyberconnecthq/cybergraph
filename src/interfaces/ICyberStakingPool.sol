// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberStakingPoolEvents } from "./ICyberStakingPoolEvents.sol";

/**
 * @title ICyberStakingPool
 * @author CyberConnect
 */
interface ICyberStakingPool is ICyberStakingPoolEvents {
    /*//////////////////////////////////////////////////////////////
                                PUBLIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit asset.
     *
     * @param asset The asset address.
     * @param amount The deposit amount.
     */
    function deposit(address asset, uint256 amount) external;

    /**
     * @notice Deposit asset for an address.
     *
     * @param to The address to deposit for.
     * @param asset The asset address.
     * @param amount The deposit amount.
     */
    function depositFor(address to, address asset, uint256 amount) external;

    /**
     * @notice Deposit ETH.
     */
    function depositETH() external payable;

    /**
     * @notice Deposit ETH for an address.
     * @param to The address to deposit for.
     */
    function depositETHFor(address to) external payable;

    /**
     * @notice Withdraw assets.
     *
     * @param receipient The receipient address.
     * @param asset The asset address.
     * @param amount The withdraw amount.
     */
    function withdraw(
        address receipient,
        address asset,
        uint256 amount
    ) external;

    /**
     * @notice Bridge assets.
     *
     * @param bridge The bridge address.
     * @param receipient The receipient address.
     * @param asset The asset address.
     * @param amount The bridge amount.
     */
    function bridge(
        address bridge,
        address receipient,
        address asset,
        uint256 amount
    ) external;

    /**
     * @notice Bridge assets with user's 712 signature.
     *
     * @param bridge The bridge address.
     * @param assetOwner The asset owner address.
     * @param receipient The receipient address.
     * @param asset The asset address.
     * @param amount The bridge amount.
     * @param deadline The deadline.
     * @param signature The 712 signature.
     */
    function bridgeWithSig(
        address bridge,
        address assetOwner,
        address receipient,
        address asset,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external;
}
