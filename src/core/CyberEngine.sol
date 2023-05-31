// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { IMiddlewareManager } from "../interfaces/IMiddlewareManager.sol";
import { IMiddleware } from "../interfaces/IMiddleware.sol";

import { DataTypes } from "../libraries/DataTypes.sol";
import { Essence } from "./Essence.sol";

/**
 * @title CyberEngine
 * @author CyberConnect
 * @notice This contract is used to create a profile NFT.
 */
contract CyberEngine is ICyberEngine {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    address public immutable SOUL;
    address public immutable MANAGER;

    mapping(address => mapping(uint256 => DataTypes.EssenceStruct))
        internal _essenceByIdByAccount;

    mapping(address => DataTypes.AccountStruct) internal _accounts;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks the sender hold a soul.
     */
    modifier onlySoulOwner() {
        require(IERC721(SOUL).balanceOf(msg.sender) > 0, "ONLY_SOUL_OWNER");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address soul, address mwManager) {
        require(soul != address(0), "SOUL_NOT_SET");
        require(mwManager != address(0), "MW_MANAGER_NOT_SET");

        SOUL = soul;
        MANAGER = mwManager;
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberEngine
    function registerEssence(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData
    ) external override onlySoulOwner returns (uint256) {
        require(
            params.mw == address(0) ||
                IMiddlewareManager(MANAGER).isMwAllowed(params.mw),
            "MW_NOT_ALLOWED"
        );

        require(bytes(params.name).length != 0, "EMPTY_NAME");
        require(bytes(params.symbol).length != 0, "EMPTY_SYMBOL");
        require(bytes(params.tokenURI).length != 0, "EMPTY_URI");

        address account = msg.sender;
        uint256 id = ++_accounts[account].essenceCount;

        _essenceByIdByAccount[account][id].name = params.name;
        _essenceByIdByAccount[account][id].symbol = params.symbol;
        _essenceByIdByAccount[account][id].tokenURI = params.tokenURI;
        _essenceByIdByAccount[account][id].transferable = params.transferable;

        if (params.mw != address(0)) {
            _essenceByIdByAccount[account][id].mw = params.mw;
            IMiddleware(params.mw).setMwData(
                account,
                DataTypes.Category.Essence,
                id,
                initData
            );
        }

        address essence = address(
            new Essence(
                account,
                id,
                params.name,
                params.symbol,
                address(this),
                params.transferable
            )
        );
        _essenceByIdByAccount[account][id].essence = essence;

        emit RegisterEssence(
            account,
            id,
            params.name,
            params.symbol,
            params.tokenURI,
            params.mw,
            essence
        );
        return id;
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberEngine
    function getEssenceTokenURI(
        address account,
        uint256 essenceId
    ) external view override returns (string memory) {
        _requireEssenceRegistered(account, essenceId);
        return _essenceByIdByAccount[account][essenceId].tokenURI;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _requireEssenceRegistered(
        address account,
        uint256 essenceId
    ) internal view {
        require(
            bytes(_essenceByIdByAccount[account][essenceId].name).length != 0,
            "ESSENCE_DOES_NOT_EXIST"
        );
    }
}
