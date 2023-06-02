// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { IMiddlewareManager } from "../interfaces/IMiddlewareManager.sol";
import { IMiddleware } from "../interfaces/IMiddleware.sol";
import { IEssence } from "../interfaces/IEssence.sol";
import { IContent } from "../interfaces/IContent.sol";
import { IW3st } from "../interfaces/IW3st.sol";

import { DataTypes } from "../libraries/DataTypes.sol";
import { Essence } from "./Essence.sol";
import { Content } from "./Content.sol";
import { W3st } from "./W3st.sol";

/**
 * @title CyberEngine
 * @author CyberConnect
 * @notice This contract is used to create a profile NFT.
 */
contract CyberEngine is ReentrancyGuard, ICyberEngine {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    address public immutable SOUL;
    address public immutable MANAGER;

    mapping(address => mapping(uint256 => DataTypes.EssenceStruct))
        internal _essenceByIdByAccount;
    mapping(address => mapping(uint256 => DataTypes.ContentStruct))
        internal _contentByIdByAccount;
    mapping(address => mapping(uint256 => DataTypes.W3stStruct))
        internal _w3stByIdByAccount;
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
    function collect(
        DataTypes.CollectParams calldata params,
        bytes calldata data
    ) external override nonReentrant returns (uint256 tokenId) {
        address collector = msg.sender;
        uint256 amount = params.amount;

        DataTypes.Category category = params.category;

        // todo check account exist
        // todo msg.send & collector?
        _checkRegistered(params.account, params.id, category);
        (address deployAddr, address mw) = _getDeployInfo(
            params.account,
            params.id,
            category
        );

        // run middleware before collecting essence
        if (mw != address(0)) {
            require(
                IMiddlewareManager(MANAGER).isMwAllowed(mw),
                "MW_NOT_ALLOWED"
            );
            IMiddleware(mw).preProcess(
                params.account,
                category,
                params.id,
                collector,
                msg.sender,
                data
            );
        }

        tokenId = _mintNFT(deployAddr, collector, params.id, amount, category);
        emit Collect(
            collector,
            params.account,
            params.id,
            amount,
            tokenId,
            category,
            data
        );
    }

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

        // todo deploy proxy using clone
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

    /// @inheritdoc ICyberEngine
    function publishContent(
        DataTypes.PublishContentParams calldata params,
        bytes calldata initData
    ) external override onlySoulOwner returns (uint256) {
        require(
            params.mw == address(0) ||
                IMiddlewareManager(MANAGER).isMwAllowed(params.mw),
            "MW_NOT_ALLOWED"
        );
        require(bytes(params.tokenURI).length != 0, "EMPTY_URI");

        address account = msg.sender;
        uint256 tokenId = ++_accounts[account].contentIdx;

        // deploy the contract for the first time
        if (tokenId == 1) {
            // todo deploy proxy using clone
            address content = address(new Content(account, address(this)));
            _accounts[account].content = content;
        }
        _contentByIdByAccount[account][tokenId].tokenURI = params.tokenURI;
        _contentByIdByAccount[account][tokenId].transferable = params
            .transferable;

        if (params.mw != address(0)) {
            _contentByIdByAccount[account][tokenId].mw = params.mw;
            IMiddleware(params.mw).setMwData(
                account,
                DataTypes.Category.Content,
                tokenId,
                initData
            );
        }
        emit PublishContent(
            account,
            tokenId,
            params.tokenURI,
            params.mw,
            _accounts[account].content
        );
        return tokenId;
    }

    /// @inheritdoc ICyberEngine
    function issueW3st(
        DataTypes.IssueW3stParams calldata params,
        bytes calldata initData
    ) external override onlySoulOwner returns (uint256) {
        // todo more ACL
        require(
            params.mw == address(0) ||
                IMiddlewareManager(MANAGER).isMwAllowed(params.mw),
            "MW_NOT_ALLOWED"
        );
        require(bytes(params.tokenURI).length != 0, "EMPTY_URI");

        address account = msg.sender;
        uint256 tokenId = ++_accounts[account].w3stIdx;

        // deploy the contract for the first time
        if (tokenId == 1) {
            // todo deploy proxy using clone
            address w3st = address(new W3st(account, address(this)));
            _accounts[account].w3st = w3st;
        }
        _w3stByIdByAccount[account][tokenId].tokenURI = params.tokenURI;
        _w3stByIdByAccount[account][tokenId].transferable = params.transferable;

        if (params.mw != address(0)) {
            _w3stByIdByAccount[account][tokenId].mw = params.mw;
            IMiddleware(params.mw).setMwData(
                account,
                DataTypes.Category.W3ST,
                tokenId,
                initData
            );
        }
        emit IssueW3st(
            account,
            tokenId,
            params.tokenURI,
            params.mw,
            _accounts[account].w3st
        );
        return tokenId;
    }

    /// @inheritdoc ICyberEngine
    function setEssenceData(
        uint256 essenceId,
        string calldata uri,
        address mw,
        bytes calldata data
    ) external override {
        // todo operator model?
        address account = msg.sender;
        require(
            mw == address(0) || IMiddlewareManager(MANAGER).isMwAllowed(mw),
            "MW_NOT_ALLOWED"
        );
        _requireEssenceRegistered(account, essenceId);
        _essenceByIdByAccount[account][essenceId].mw = mw;
        if (mw != address(0)) {
            IMiddleware(mw).setMwData(
                account,
                DataTypes.Category.Essence,
                essenceId,
                data
            );
        }
        _essenceByIdByAccount[account][essenceId].tokenURI = uri;
        emit SetEssenceData(account, essenceId, uri, mw);
    }

    /// @inheritdoc ICyberEngine
    function setContentData(
        uint256 tokenId,
        string calldata uri,
        address mw,
        bytes calldata data
    ) external override {
        // todo operator model?
        address account = msg.sender;
        require(
            mw == address(0) || IMiddlewareManager(MANAGER).isMwAllowed(mw),
            "MW_NOT_ALLOWED"
        );
        _requireContentRegistered(account, tokenId);
        _contentByIdByAccount[account][tokenId].mw = mw;
        if (mw != address(0)) {
            IMiddleware(mw).setMwData(
                account,
                DataTypes.Category.Content,
                tokenId,
                data
            );
        }
        _contentByIdByAccount[account][tokenId].tokenURI = uri;
        emit SetContentData(account, tokenId, uri, mw);
    }

    /// @inheritdoc ICyberEngine
    function setW3stData(
        uint256 tokenId,
        string calldata uri,
        address mw,
        bytes calldata data
    ) external override {
        // todo operator model?
        address account = msg.sender;
        require(
            mw == address(0) || IMiddlewareManager(MANAGER).isMwAllowed(mw),
            "MW_NOT_ALLOWED"
        );
        _requireW3stRegistered(account, tokenId);
        _w3stByIdByAccount[account][tokenId].mw = mw;
        if (mw != address(0)) {
            IMiddleware(mw).setMwData(
                account,
                DataTypes.Category.W3ST,
                tokenId,
                data
            );
        }
        _w3stByIdByAccount[account][tokenId].tokenURI = uri;
        emit SetW3stData(account, tokenId, uri, mw);
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

    /// @inheritdoc ICyberEngine
    function getContentTokenURI(
        address account,
        uint256 tokenID
    ) external view override returns (string memory) {
        _requireContentRegistered(account, tokenID);
        return _contentByIdByAccount[account][tokenID].tokenURI;
    }

    /// @inheritdoc ICyberEngine
    function getContentTransferability(
        address account,
        uint256 tokenID
    ) external view override returns (bool) {
        _requireContentRegistered(account, tokenID);
        return _contentByIdByAccount[account][tokenID].transferable;
    }

    /// @inheritdoc ICyberEngine
    function getW3stTokenURI(
        address account,
        uint256 tokenID
    ) external view override returns (string memory) {
        _requireW3stRegistered(account, tokenID);
        return _w3stByIdByAccount[account][tokenID].tokenURI;
    }

    /// @inheritdoc ICyberEngine
    function getW3stTransferability(
        address account,
        uint256 tokenID
    ) external view override returns (bool) {
        _requireW3stRegistered(account, tokenID);
        return _w3stByIdByAccount[account][tokenID].transferable;
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

    function _requireContentRegistered(
        address account,
        uint256 tokenId
    ) internal view {
        require(
            _accounts[account].contentIdx > tokenId,
            "CONTENT_DOES_NOT_EXIST"
        );
    }

    function _requireW3stRegistered(
        address account,
        uint256 tokenId
    ) internal view {
        require(_accounts[account].w3stIdx > tokenId, "W3ST_DOES_NOT_EXIST");
    }

    function _checkRegistered(
        address account,
        uint256 id,
        DataTypes.Category category
    ) internal view {
        if (category == DataTypes.Category.W3ST) {
            _requireW3stRegistered(account, id);
        } else if (category == DataTypes.Category.Content) {
            _requireContentRegistered(account, id);
        } else if (category == DataTypes.Category.Essence) {
            _requireEssenceRegistered(account, id);
        } else {
            revert("WRONG_CATEGORY");
        }
    }

    function _getDeployInfo(
        address account,
        uint256 id,
        DataTypes.Category category
    ) internal view returns (address deployAddr, address mw) {
        if (category == DataTypes.Category.W3ST) {
            deployAddr = _accounts[account].w3st;
            mw = _w3stByIdByAccount[account][id].mw;
        } else if (category == DataTypes.Category.Content) {
            deployAddr = _accounts[account].content;
            mw = _contentByIdByAccount[account][id].mw;
        } else if (category == DataTypes.Category.Essence) {
            deployAddr = _essenceByIdByAccount[account][id].essence;
            mw = _essenceByIdByAccount[account][id].mw;
        } else {
            revert("WRONG_CATEGORY");
        }
    }

    function _mintNFT(
        address deployAddr,
        address collector,
        uint256 id,
        uint256 amount,
        DataTypes.Category category
    ) internal returns (uint256 tokenId) {
        if (category == DataTypes.Category.W3ST) {
            IW3st(deployAddr).mint(collector, id, amount, new bytes(0));
        } else if (category == DataTypes.Category.Content) {
            IContent(deployAddr).mint(collector, id, amount, new bytes(0));
        } else if (category == DataTypes.Category.Essence) {
            require(amount == 1, "INCORRECT_COLLECT_AMOUNT");
            tokenId = IEssence(deployAddr).mint(collector);
        } else {
            revert("WRONG_CATEGORY");
        }
    }
}
