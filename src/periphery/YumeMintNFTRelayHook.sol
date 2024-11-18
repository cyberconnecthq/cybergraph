// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { RelayParams, IYumeRelayGateHook } from "../interfaces/IYumeRelayGateHook.sol";
import { IYumeEngine } from "../interfaces/IYumeEngine.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

/**
 * @title YumeMintNFTRelayHook
 */
contract YumeMintNFTRelayHook is IYumeRelayGateHook, Ownable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

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

    mapping(uint256 => MintFeeConfig) public mintFeeConfigs;
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

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
        if (bytes4(data[0:4]) == IYumeEngine.createCollection.selector) {
            return
                processCreateCollectionRelay(
                    msgSender,
                    chainId,
                    entryPoint,
                    data[4:]
                );
        } else if (bytes4(data[0:4]) == IYumeEngine.createToken.selector) {
            return
                processCreateTokenRelay(
                    msgSender,
                    chainId,
                    entryPoint,
                    data[4:]
                );
        } else if (bytes4(data[0:4]) == IYumeEngine.mintWithEth.selector) {
            return processMintRelay(msgSender, chainId, entryPoint, data[4:]);
        } else {
            revert("INVALID_ACTION");
        }
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
            _configMintFee(
                params[i].chainId,
                params[i].enabled,
                params[i].recipient,
                params[i].fee
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                                PRIVATE
    //////////////////////////////////////////////////////////////*/

    function processCreateCollectionRelay(
        address msgSender,
        uint256 chainId,
        address entryPoint,
        bytes calldata data
    ) private returns (RelayParams memory) {
        (
            DataTypes.CreateTokenParams memory params,
            string memory collectionName
        ) = abi.decode(data, (DataTypes.CreateTokenParams, string));

        require(bytes(collectionName).length != 0, "INVALID_COLLECTION_NAME");
        require(params.rewards.length != 0, "INVALID_CREATOR_REWARDS");

        MintFeeConfig memory mintFeeConfig = mintFeeConfigs[chainId];
        require(mintFeeConfig.enabled, "MINT_FEE_NOT_ALLOWED");

        _chargeAndRefundOverPayment(
            msgSender,
            mintFeeConfig.recipient,
            mintFeeConfig.fee
        );

        RelayParams memory relayParams;
        relayParams.to = entryPoint;
        relayParams.value = 0;
        relayParams.callData = abi.encodeWithSelector(
            IYumeEngine.createCollection.selector,
            params,
            collectionName,
            msg.sender
        );
        return relayParams;
    }

    function processCreateTokenRelay(
        address msgSender,
        uint256 chainId,
        address entryPoint,
        bytes calldata data
    ) private returns (RelayParams memory) {
        (address nft, DataTypes.CreateTokenParams memory params) = abi.decode(
            data,
            (address, DataTypes.CreateTokenParams)
        );

        require(nft != address(0), "INVALID_NFT_ADDRESS");
        require(params.rewards.length != 0, "INVALID_CREATOR_REWARDS");

        MintFeeConfig memory mintFeeConfig = mintFeeConfigs[chainId];
        require(mintFeeConfig.enabled, "MINT_FEE_NOT_ALLOWED");

        _chargeAndRefundOverPayment(
            msgSender,
            mintFeeConfig.recipient,
            mintFeeConfig.fee
        );

        RelayParams memory relayParams;
        relayParams.to = entryPoint;
        relayParams.value = 0;
        relayParams.callData = abi.encodeWithSelector(
            IYumeEngine.createToken.selector,
            nft,
            params
        );
        return relayParams;
    }

    function processMintRelay(
        address msgSender,
        uint256 chainId,
        address entryPoint,
        bytes calldata data
    ) private returns (RelayParams memory) {
        (
            address nft,
            uint256 tokenId,
            address to,
            uint256 amount,
            address mintReferral,
            bytes memory mintData,
            uint256 price
        ) = abi.decode(
                data,
                (address, uint256, address, uint256, address, bytes, uint256)
            );

        require(entryPoint != address(0), "INVALID_DESTINATION");
        require(nft != address(0), "INVALID_NFT");
        require(to != address(0), "INVALID_TO");
        require(amount > 0, "INVALID_AMOUNT");

        MintFeeConfig memory mintFeeConfig = mintFeeConfigs[chainId];
        require(mintFeeConfig.enabled, "MINT_FEE_NOT_ALLOWED");

        uint256 cost = price * amount;
        _chargeAndRefundOverPayment(
            msgSender,
            mintFeeConfig.recipient,
            cost + mintFeeConfig.fee
        );

        RelayParams memory relayParams;
        relayParams.to = entryPoint;
        relayParams.value = cost;
        relayParams.callData = abi.encodeWithSelector(
            IYumeEngine.mintWithEth.selector,
            nft,
            tokenId,
            to,
            amount,
            mintReferral,
            mintData
        );
        return relayParams;
    }

    function _configMintFee(
        uint256 chainId,
        bool enabled,
        address recipient,
        uint256 fee
    ) private {
        require(recipient != address(0), "INVALID_RECIPIENT");
        mintFeeConfigs[chainId] = MintFeeConfig(enabled, recipient, fee);
        emit MintFeeConfigUpdated(chainId, enabled, recipient, fee);
    }

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
