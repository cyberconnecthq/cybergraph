// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ICyberRelayGateHook.sol";

/**
 * @title CyberMintNFTRelayHook
 * @author Cyber
 */
contract CyberMintNFTRelayHook is ICyberRelayGateHook, Ownable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    struct MintFeeConfig {
        bool enabled;
        address recipient;
        uint256 fee;
    }

    mapping(address => mapping(uint256 => mapping(address => MintFeeConfig))) mintFeeConfigs;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event MintFeeConfigUpdated(
        address nft,
        uint256 tokenId,
        address feeToken,
        bool enabled,
        address recipient,
        uint256 fee
    );

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                    ICyberRelayGateHook OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function processRelay(
        address msgSender,
        address destination,
        bytes calldata data
    ) external payable override returns (RelayParams memory) {
        (uint256 tokenId, address feeToken, address to, uint256 amount) = abi
            .decode(data, (uint256, address, address, uint256));

        require(destination != address(0), "INVALID_DESTINATION");
        require(to != address(0), "INVALID_TO");
        require(amount > 0, "INVALID_AMOUNT");

        MintFeeConfig memory mintFeeConfig = mintFeeConfigs[destination][
            tokenId
        ][feeToken];
        require(mintFeeConfig.enabled, "MINT_FEE_NOT_ALLOWED");
        if (mintFeeConfig.fee > 0) {
            if (feeToken == address(0)) {
                _chargeAndRefundOverPayment(
                    msgSender,
                    mintFeeConfig.recipient,
                    mintFeeConfig.fee * amount
                );
            } else {
                IERC20(feeToken).safeTransferFrom(
                    msgSender,
                    mintFeeConfig.recipient,
                    mintFeeConfig.fee * amount
                );
            }
        }

        RelayParams memory relayParams;
        relayParams.to = destination;
        relayParams.value = 0;
        relayParams.callData = abi.encodeWithSignature(
            "mint(address,uint256,uint256)",
            to,
            tokenId,
            amount
        );
        return relayParams;
    }

    /*//////////////////////////////////////////////////////////////
                    ONLY OWNER
    //////////////////////////////////////////////////////////////*/

    function rescueToken(address token) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = owner().call{ value: address(this).balance }("");
            require(success, "WITHDRAW_FAILED");
        } else {
            IERC20(token).safeTransfer(
                owner(),
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    function configMintFee(
        address nft,
        uint256 tokenId,
        address feeToken,
        bool enabled,
        address recipient,
        uint256 fee
    ) external onlyOwner {
        require(nft != address(0), "INVALID_NFT");
        require(recipient != address(0), "INVALID_RECIPIENT");
        mintFeeConfigs[nft][tokenId][feeToken] = MintFeeConfig(
            enabled,
            recipient,
            fee
        );
        emit MintFeeConfigUpdated(
            nft,
            tokenId,
            feeToken,
            enabled,
            recipient,
            fee
        );
    }

    /*//////////////////////////////////////////////////////////////
                    PRIVATE
    //////////////////////////////////////////////////////////////*/

    function _chargeAndRefundOverPayment(
        address refundTo,
        address recipient,
        uint256 cost
    ) internal {
        require(msg.value >= cost, "INSUFFICIENT_FUNDS");
        /**
         * Already checked msg.value >= cost
         */
        uint256 overpayment;
        unchecked {
            overpayment = msg.value - cost;
        }

        if (overpayment > 0) {
            (bool refundSuccess, ) = refundTo.call{ value: overpayment }("");
            require(refundSuccess, "REFUND_FAILED");
        }
        if (cost > 0) {
            (bool chargeSuccess, ) = recipient.call{ value: cost }("");
            require(chargeSuccess, "CHARGE_FAILED");
        }
    }
}
