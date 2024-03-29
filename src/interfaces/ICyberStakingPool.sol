// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberStakingPoolEvents } from "./ICyberStakingPoolEvents.sol";

struct EIP712Signature {
    uint256 deadline;
    bytes signature;
}

struct BridgeParams {
    address bridgeAddress;
    address recipient;
    address[] assets;
    uint256[] amounts;
}

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
     * @notice Deposit ETH.
     */
    function depositETH() external payable;

    /**
     * @notice Withdraw assets.
     *
     * @param assets The asset addresses.
     * @param amounts The withdraw amounts.
     */
    function withdraw(
        address[] calldata assets,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Bridge assets.
     *
     * @param params The bridge params.
     */
    function bridge(BridgeParams calldata params) external;

    /**
     * @notice Bridge assets with asset owner's 712 signature.
     *
     * @param assetOwner The asset owner address.
     * @param params The bridge params.
     * @param signature The 712 signature.
     */
    function bridgeWithSig(
        address assetOwner,
        BridgeParams calldata params,
        EIP712Signature calldata signature
    ) external;
}
