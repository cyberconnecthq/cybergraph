// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IYumeRelayGateHook.sol";

/**
 * @title YumeMintNFTRelayHook
 */
contract YumeMintNFTRelayHook is IYumeRelayGateHook, Ownable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    struct MintPriceConfig {
        bool enabled;
        address recipient;
        uint256 price;
    }

    struct MintFeeConfig {
        bool enabled;
        address recipient;
        uint256 fee;
    }

    struct BatchConfigMintFeeParams {
        uint256 chainId;
        bool enabled;
        address recipient;
        uint256 fee;
    }

    mapping(uint256 => mapping(address => mapping(address => mapping(uint256 => MintPriceConfig))))
        public mintPriceConfigs;

    mapping(uint256 => MintFeeConfig) public mintFeeConfigs;
    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event MintPriceConfigUpdated(
        uint256 chainId,
        address entryPoint,
        address nft,
        uint256 tokenId,
        bool enabled,
        address recipient,
        uint256 price
    );

    event MintFeeConfigUpdated(
        uint256 chainId,
        bool enabled,
        address recipient,
        uint256 price
    );

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                    IYumeRelayGateHook OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function processRelay(
        address msgSender,
        uint256 chainId,
        address entryPoint,
        bytes calldata data
    ) external payable override returns (RelayParams memory) {
        (address to, address nft, uint256 tokenId, uint256 amount) = abi
            .decode(data, (address, address, uint256, uint256));

        require(entryPoint != address(0), "INVALID_DESTINATION");
        require(nft != address(0), "INVALID_NFT");
        require(to != address(0), "INVALID_TO");
        require(amount > 0, "INVALID_AMOUNT");

        MintFeeConfig memory mintFeeConfig = mintFeeConfigs[chainId];
        require(mintFeeConfig.enabled, "MINT_FEE_NOT_ALLOWED");

        MintPriceConfig memory mintPriceConfig = mintPriceConfigs[chainId][entryPoint][nft][tokenId];
        require(mintPriceConfig.enabled, "MINT_PRICE_NOT_ALLOWED");

        uint256 cost =  mintPriceConfig.price * amount;
        _chargeAndRefundOverPayment(
            msgSender,
            mintPriceConfig.recipient,
            cost,
            mintFeeConfig.recipient,
            mintFeeConfig.fee
        );

        RelayParams memory relayParams;
        relayParams.to = entryPoint;
        relayParams.value = cost;
        relayParams.callData = abi.encodeWithSignature(
            "mint(address, address, uint256, uint256)",
            to,
            nft,
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

    function configMintPrice(
        uint256 chainId,
        address entryPoint,
        address nft,
        uint256 tokenId,
        bool enabled,
        address recipient,
        uint256 price
    ) external onlyOwner {
        require(nft != address(0), "INVALID_NFT");
        require(recipient != address(0), "INVALID_RECIPIENT");

        MintFeeConfig memory mintFeeConfig = mintFeeConfigs[chainId];
        require(mintFeeConfig.enabled, "INVALID_CHAIN_ID");

        mintPriceConfigs[chainId][entryPoint][nft][tokenId] = MintPriceConfig(
            enabled,
            recipient,
            price
        );
        emit MintPriceConfigUpdated(
            chainId,
            entryPoint,
            nft,
            tokenId,
            enabled,
            recipient,
            price
        );
    }

    function configMintFee(
        uint256 chainId,
        bool enabled,
        address recipient,
        uint256 fee
    ) external onlyOwner {
        _configMintFee(chainId, enabled, recipient, fee);
    }

    function batchConfigMintFee(
        BatchConfigMintFeeParams[] calldata params
    ) external onlyOwner {
        for (uint256 i = 0; i < params.length; i++) {
            _configMintFee(params[i].chainId, params[i].enabled, params[i].recipient, params[i].fee);
        }
    }

    function _configMintFee(
        uint256 chainId,
        bool enabled,
        address recipient,
        uint256 fee
    ) internal {
        require(recipient != address(0), "INVALID_RECIPIENT");
        mintFeeConfigs[chainId] = MintFeeConfig(
            enabled,
            recipient,
            fee
        );
        emit MintFeeConfigUpdated(
            chainId,
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
        address costRecipient,
        uint256 cost,
        address feeRecipient,
        uint256 fee
    ) internal {
        require(msg.value >= cost + fee, "INSUFFICIENT_FUNDS");
        /**
         * Already checked msg.value >= cost
         */
        uint256 overpayment;
        unchecked {
            overpayment = msg.value - cost - fee;
        }

        if (overpayment > 0) {
            (bool refundSuccess, ) = refundTo.call{ value: overpayment }("");
            require(refundSuccess, "REFUND_FAILED");
        }
        if (costRecipient != feeRecipient)  {
            if (cost > 0) {
                (bool costChargeSuccess, ) = costRecipient.call{ value: cost }("");
                require(costChargeSuccess, "COST_CHARGE_FAILED");
            }
            if (fee > 0) {
                (bool feeChargeSuccess, ) = feeRecipient.call{ value: fee }("");
                require(feeChargeSuccess, "FEE_CHARGE_FAILED");
            }
        } else {
            if (cost + fee > 0) {
                (bool chargeSuccess, ) = costRecipient.call{ value: cost + fee }("");
                require(chargeSuccess, "CHARGE_FAILED");
            }
        }
    }
}
