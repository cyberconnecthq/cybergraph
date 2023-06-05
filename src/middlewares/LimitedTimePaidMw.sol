// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";
import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import { IMiddleware } from "../interfaces/IMiddleware.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { FeeMw } from "./base/FeeMw.sol";

/**
 * @title  LimitedTimePaid Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to only allow users to collect when they pay a certain fee.
 * the issuer can choose to set rules including whether collecting this require soul holder,
 * start/end time and has a total supply.
 */
contract LimitedTimePaidMw is IMiddleware, FeeMw {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyEngine() {
        require(ENGINE == msg.sender, "ONLY_ENGINE");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENT
    //////////////////////////////////////////////////////////////*/

    event CollectLimitedTimePaidMwSet(
        address indexed account,
        DataTypes.Category indexed category,
        uint256 indexed id,
        uint256 totalSupply,
        uint256 price,
        address recipient,
        address currency,
        uint256 endTimestamp,
        uint256 startTimestamp,
        uint16 referralFee,
        bool soulRequired
    );

    /*//////////////////////////////////////////////////////////////
                               STATES
    //////////////////////////////////////////////////////////////*/

    struct LimitedTimePaidData {
        uint256 totalSupply;
        uint256 currentCollect;
        uint256 price;
        address recipient;
        address currency;
        uint256 endTimestamp;
        uint256 startTimestamp;
        uint16 referralFee;
        bool soulRequired;
    }

    mapping(address => mapping(DataTypes.Category => mapping(uint256 => LimitedTimePaidData)))
        internal _data;
    address public immutable SOUL;
    address public immutable ENGINE;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address treasury,
        address engine,
        address soul
    ) FeeMw(treasury) {
        ENGINE = engine;
        SOUL = soul;
    }

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IMiddleware
     * @notice Stores the parameters for setting up the limited time paid essence middleware, checks if the recipient, total suppply
     * start/end time is valid and currency is approved.
     */
    function setMwData(
        address account,
        DataTypes.Category category,
        uint256 id,
        bytes calldata data
    ) external override onlyEngine {
        (
            uint256 totalSupply,
            uint256 price,
            address recipient,
            address currency,
            uint256 endTimestamp,
            uint256 startTimestamp,
            uint16 referralFee,
            bool soulRequired
        ) = abi.decode(
                data,
                (
                    uint256,
                    uint256,
                    address,
                    address,
                    uint256,
                    uint256,
                    uint16,
                    bool
                )
            );

        require(recipient != address(0), "INVALID_RECIPENT");
        require(totalSupply > 0, "INVALID_TOTAL_SUPPLY");
        require(price > 0, "INVALID_PRICE");
        require(endTimestamp > startTimestamp, "INVALID_TIME_RANGE");
        require(_currencyAllowed(currency), "CURRENCY_NOT_ALLOWED");
        require(referralFee <= Constants._MAX_BPS, "INVALID_REFERRAL_FEE");

        _data[account][category][id].totalSupply = totalSupply;
        _data[account][category][id].price = price;
        _data[account][category][id].recipient = recipient;
        _data[account][category][id].soulRequired = soulRequired;
        _data[account][category][id].startTimestamp = startTimestamp;
        _data[account][category][id].endTimestamp = endTimestamp;
        _data[account][category][id].currency = currency;
        _data[account][category][id].referralFee = referralFee;

        emit CollectLimitedTimePaidMwSet(
            account,
            category,
            id,
            totalSupply,
            price,
            recipient,
            currency,
            endTimestamp,
            startTimestamp,
            referralFee,
            soulRequired
        );
    }

    function preProcess(
        address account,
        DataTypes.Category category,
        uint256 id,
        address collector,
        address,
        address referrerAccount,
        bytes calldata
    ) external override onlyEngine {
        require(
            _data[account][category][id].totalSupply >
                _data[account][category][id].currentCollect,
            "COLLECT_LIMIT_EXCEEDED"
        );

        require(
            block.timestamp >= _data[account][category][id].startTimestamp,
            "NOT_STARTED"
        );

        require(
            block.timestamp <= _data[account][category][id].endTimestamp,
            "ENDED"
        );

        if (_data[account][category][id].soulRequired) {
            require(_checkSoul(collector), "NOT_SOUL_OWNER");
        }

        uint256 price = _data[account][category][id].price;
        address currency = _data[account][category][id].currency;
        uint256 treasuryCollected = (price * _treasuryFee()) /
            Constants._MAX_BPS;
        uint256 creatorCollected = price - treasuryCollected;

        if (
            account != referrerAccount &&
            _data[account][category][id].referralFee > 0
        ) {
            uint256 referrerCollected = (creatorCollected *
                _data[account][category][id].referralFee) / Constants._MAX_BPS;
            creatorCollected = creatorCollected - referrerCollected;

            IERC20(currency).safeTransferFrom(
                collector,
                referrerAccount,
                referrerCollected
            );
        }

        IERC20(currency).safeTransferFrom(
            collector,
            _data[account][category][id].recipient,
            creatorCollected
        );

        if (treasuryCollected > 0) {
            IERC20(currency).safeTransferFrom(
                collector,
                _treasuryAddress(),
                treasuryCollected
            );
        }

        ++_data[account][category][id].currentCollect;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _checkSoul(address collector) internal view returns (bool) {
        return (IERC721(SOUL).balanceOf(collector) > 0);
    }
}
