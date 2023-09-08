// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IMiddleware } from "../interfaces/IMiddleware.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

import { OnlyEngineMw } from "./base/OnlyEngineMw.sol";
import { CyberNFT1155 } from "../base/CyberNFT1155.sol";
import { CyberNFT721 } from "../base/CyberNFT721.sol";

/**
 * @title  LimitedOnlyOnce Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to only allow users to collect only once.
 * The issuer can set a total supply.
 */
contract LimitedOnlyOnceMw is IMiddleware, OnlyEngineMw {
    /*//////////////////////////////////////////////////////////////
                                EVENT
    //////////////////////////////////////////////////////////////*/
    event CollectLimitedOnlyOnceMwSet(
        address indexed account,
        DataTypes.Category indexed category,
        uint256 indexed id,
        uint256 totalSupply
    );

    /*//////////////////////////////////////////////////////////////
                               STATES
    //////////////////////////////////////////////////////////////*/

    struct LimitedOnlyOnceData {
        uint256 totalSupply;
    }

    mapping(address => mapping(DataTypes.Category => mapping(uint256 => LimitedOnlyOnceData)))
        internal _data;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address engine) OnlyEngineMw(engine) {}

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function setMwData(
        address account,
        DataTypes.Category category,
        uint256 id,
        bytes calldata data
    ) external override onlyEngine {
        uint256 totalSupply = abi.decode(data, (uint256));
        require(totalSupply > 0, "INVALID_TOTAL_SUPPLY");
        _data[account][category][id].totalSupply = totalSupply;
        emit CollectLimitedOnlyOnceMwSet(account, category, id, totalSupply);
    }

    function preProcess(
        DataTypes.MwParams calldata params
    ) external view override onlyEngine {
        require(params.amount == 1, "INCORRECT_COLLECT_AMOUNT");
        uint256 balance;
        uint256 totalSupply;
        if (params.category == DataTypes.Category.W3ST) {
            address w3stAddr = ICyberEngine(ENGINE).getW3stAddr(params.account);
            balance = CyberNFT1155(w3stAddr).balanceOf(params.to, params.id);
            totalSupply = CyberNFT1155(w3stAddr).totalSupply(params.id);
        } else if (params.category == DataTypes.Category.Content) {
            address contentAddr = ICyberEngine(ENGINE).getContentAddr(
                params.account
            );
            balance = CyberNFT1155(contentAddr).balanceOf(params.to, params.id);
            totalSupply = CyberNFT1155(contentAddr).totalSupply(params.id);
        } else if (params.category == DataTypes.Category.Essence) {
            address essenceAddr = ICyberEngine(ENGINE).getEssenceAddr(
                params.account,
                params.id
            );
            balance = CyberNFT721(essenceAddr).balanceOf(params.to);
            totalSupply = CyberNFT721(essenceAddr).totalSupply();
        } else {
            revert("WRONG_CATEGORY");
        }
        require(balance == 0, "ALREADY_COLLECTED");
        require(
            _data[params.account][params.category][params.id].totalSupply >
                totalSupply,
            "COLLECT_LIMIT_EXCEEDED"
        );
    }
}
