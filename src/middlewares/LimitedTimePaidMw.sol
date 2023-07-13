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
import { OnlyEngineMw } from "./base/OnlyEngineMw.sol";

/**
 * @title  LimitedTimePaid Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to only allow users to collect when they pay a certain fee.
 * the issuer can choose to set rules including whether collecting this require soul holder,
 * start/end time and has a total supply.
 */
contract LimitedTimePaidMw is IMiddleware, FeeMw, OnlyEngineMw {
    using SafeERC20 for IERC20;

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

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address treasury,
        address engine,
        address soul
    ) FeeMw(treasury) OnlyEngineMw(engine) {
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
        DataTypes.MwParams calldata params
    ) external override onlyEngine {
        require(params.amount == 1, "INCORRECT_COLLECT_AMOUNT");
        require(
            _data[params.account][params.category][params.id].totalSupply >
                _data[params.account][params.category][params.id]
                    .currentCollect,
            "COLLECT_LIMIT_EXCEEDED"
        );

        require(
            block.timestamp >=
                _data[params.account][params.category][params.id]
                    .startTimestamp,
            "NOT_STARTED"
        );

        require(
            block.timestamp <=
                _data[params.account][params.category][params.id].endTimestamp,
            "ENDED"
        );

        if (_data[params.account][params.category][params.id].soulRequired) {
            require(_checkSoul(params.to), "NOT_SOUL_OWNER");
        }

        uint256 price = _data[params.account][params.category][params.id].price;
        address currency = _data[params.account][params.category][params.id]
            .currency;
        uint256 treasuryCollected = (price * _treasuryFee()) /
            Constants._MAX_BPS;
        uint256 creatorCollected = price - treasuryCollected;

        if (
            params.account != params.referrerAccount &&
            _data[params.account][params.category][params.id].referralFee > 0
        ) {
            uint256 referrerCollected = (creatorCollected *
                _data[params.account][params.category][params.id].referralFee) /
                Constants._MAX_BPS;
            creatorCollected = creatorCollected - referrerCollected;

            IERC20(currency).safeTransferFrom(
                params.from,
                params.referrerAccount,
                referrerCollected
            );
        }

        IERC20(currency).safeTransferFrom(
            params.from,
            _data[params.account][params.category][params.id].recipient,
            creatorCollected
        );

        if (treasuryCollected > 0) {
            IERC20(currency).safeTransferFrom(
                params.from,
                _treasuryAddress(),
                treasuryCollected
            );
        }

        ++_data[params.account][params.category][params.id].currentCollect;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _checkSoul(address collector) internal view returns (bool) {
        return (IERC721(SOUL).balanceOf(collector) > 0);
    }
}
