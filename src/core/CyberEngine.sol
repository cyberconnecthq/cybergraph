// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { Clones } from "openzeppelin-contracts/contracts/proxy/Clones.sol";

import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { IMiddlewareManager } from "../interfaces/IMiddlewareManager.sol";
import { IMiddleware } from "../interfaces/IMiddleware.sol";
import { IEssence } from "../interfaces/IEssence.sol";
import { IContent } from "../interfaces/IContent.sol";
import { IW3st } from "../interfaces/IW3st.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

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

    address internal immutable ESSENCE_IMPL;
    address internal immutable CONTENT_IMPL;
    address internal immutable W3ST_IMPL;

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

    constructor(
        address soul,
        address mwManager,
        address essImpl,
        address contentImpl,
        address w3stImpl
    ) {
        require(soul != address(0), "SOUL_NOT_SET");
        require(mwManager != address(0), "MW_MANAGER_NOT_SET");
        require(essImpl != address(0), "ESS_IMPL_NOT_SET");
        require(contentImpl != address(0), "CONTENT_IMPL_NOT_SET");
        require(w3stImpl != address(0), "W3ST_IMPL_NOT_SET");

        SOUL = soul;
        MANAGER = mwManager;
        ESSENCE_IMPL = essImpl;
        CONTENT_IMPL = contentImpl;
        W3ST_IMPL = w3stImpl;
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

        // todo check account exist
        // todo msg.send & collector?
        _checkRegistered(params.account, params.id, params.category);

        (address account, uint256 id) = _getSrcIfShared(
            params.account,
            params.id
        );
        (address deployAddr, address mw) = _getDeployInfo(
            account,
            id,
            params.category
        );

        if (mw != address(0)) {
            require(
                IMiddlewareManager(MANAGER).isMwAllowed(mw),
                "MW_NOT_ALLOWED"
            );
            IMiddleware(mw).preProcess(
                account,
                params.category,
                id,
                collector,
                msg.sender,
                params.account,
                data
            );
        }

        tokenId = _mintNFT(
            deployAddr,
            collector,
            id,
            params.amount,
            params.category
        );
        emit Collect(
            collector,
            account,
            id,
            params.amount,
            tokenId,
            params.category,
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

        address account = msg.sender;
        uint256 id = _accounts[account].essenceCount;

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

        address essence = Clones.clone(ESSENCE_IMPL);
        IEssence(essence).initialize(
            account,
            id,
            params.name,
            params.symbol,
            params.transferable
        );
        _essenceByIdByAccount[account][id].essence = essence;
        ++_accounts[account].essenceCount;

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

        address account = msg.sender;
        uint256 tokenId = _accounts[account].contentCount;

        // deploy the contract for the first time
        if (tokenId == 0) {
            address content = Clones.clone(CONTENT_IMPL);
            IContent(content).initialize(account);
            _accounts[account].content = content;
        }
        _contentByIdByAccount[account][tokenId].contentType = DataTypes
            .ContentType
            .Content;
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

        ++_accounts[account].contentCount;

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
    function share(
        DataTypes.ShareParams calldata params
    ) external override onlySoulOwner returns (uint256) {
        _requireContentRegistered(params.accountShared, params.idShared);

        (address srcAccount, uint256 srcId) = _getSrcIfShared(
            params.accountShared,
            params.idShared
        );
        address account = msg.sender;
        uint256 tokenId = _accounts[account].contentCount;

        // deploy the contract for the first time
        if (tokenId == 0) {
            address content = Clones.clone(CONTENT_IMPL);
            IContent(content).initialize(account);
            _accounts[account].content = content;
        }

        _contentByIdByAccount[account][tokenId].contentType = DataTypes
            .ContentType
            .Share;
        _contentByIdByAccount[account][tokenId].srcAccount = srcAccount;
        _contentByIdByAccount[account][tokenId].srcId = srcId;

        ++_accounts[account].contentCount;
        emit Share(account, tokenId, srcAccount, srcId);
        return tokenId;
    }

    /// @inheritdoc ICyberEngine
    function comment(
        DataTypes.CommentParams calldata params,
        bytes calldata initData
    ) external override onlySoulOwner returns (uint256) {
        require(
            params.mw == address(0) ||
                IMiddlewareManager(MANAGER).isMwAllowed(params.mw),
            "MW_NOT_ALLOWED"
        );

        _requireContentRegistered(params.accountCommented, params.idCommented);

        address account = msg.sender;
        uint256 tokenId = _accounts[account].contentCount;

        // deploy the contract for the first time
        if (tokenId == 0) {
            address content = Clones.clone(CONTENT_IMPL);
            IContent(content).initialize(account);
            _accounts[account].content = content;
        }
        _contentByIdByAccount[account][tokenId].contentType = DataTypes
            .ContentType
            .Comment;
        _contentByIdByAccount[account][tokenId].tokenURI = params.tokenURI;
        _contentByIdByAccount[account][tokenId].transferable = params
            .transferable;
        _contentByIdByAccount[account][tokenId].srcAccount = params
            .accountCommented;
        _contentByIdByAccount[account][tokenId].srcId = params.idCommented;

        if (params.mw != address(0)) {
            _contentByIdByAccount[account][tokenId].mw = params.mw;
            IMiddleware(params.mw).setMwData(
                account,
                DataTypes.Category.Content,
                tokenId,
                initData
            );
        }

        ++_accounts[account].contentCount;
        emit Comment(
            account,
            tokenId,
            params.tokenURI,
            params.mw,
            _accounts[account].content,
            params.accountCommented,
            params.idCommented
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

        address account = msg.sender;
        uint256 tokenId = _accounts[account].w3stCount;

        // deploy the contract for the first time
        if (tokenId == 0) {
            address w3st = Clones.clone(W3ST_IMPL);
            IW3st(w3st).initialize(account);
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

        ++_accounts[account].w3stCount;
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

        require(
            _contentByIdByAccount[account][tokenId].contentType !=
                DataTypes.ContentType.Share,
            "CANNOT_SET_DATA_FOR_SHARE"
        );
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
    function getEssenceAddr(
        address account,
        uint256 essenceId
    ) external view override returns (address) {
        _requireEssenceRegistered(account, essenceId);
        return _essenceByIdByAccount[account][essenceId].essence;
    }

    /// @inheritdoc ICyberEngine
    function getEssenceMw(
        address account,
        uint256 essenceId
    ) external view override returns (address) {
        _requireEssenceRegistered(account, essenceId);
        return _essenceByIdByAccount[account][essenceId].mw;
    }

    /// @inheritdoc ICyberEngine
    function getEssenceCount(
        address account
    ) external view override returns (uint256) {
        return _accounts[account].essenceCount;
    }

    /// @inheritdoc ICyberEngine
    function getEssenceTransferability(
        address account,
        uint256 essenceId
    ) external view override returns (bool) {
        _requireEssenceRegistered(account, essenceId);
        return _essenceByIdByAccount[account][essenceId].transferable;
    }

    /// @inheritdoc ICyberEngine
    function getContentTokenURI(
        address account,
        uint256 tokenID
    ) external view override returns (string memory) {
        _requireContentRegistered(account, tokenID);
        (address srcAccount, uint256 srcId) = _getSrcIfShared(account, tokenID);
        return _contentByIdByAccount[srcAccount][srcId].tokenURI;
    }

    /// @inheritdoc ICyberEngine
    function getContentSrcInfo(
        address account,
        uint256 tokenID
    ) external view override returns (address, uint256) {
        _requireContentRegistered(account, tokenID);
        return (
            _contentByIdByAccount[account][tokenID].srcAccount,
            _contentByIdByAccount[account][tokenID].srcId
        );
    }

    /// @inheritdoc ICyberEngine
    function getContentAddr(
        address account
    ) external view override returns (address) {
        return _accounts[account].content;
    }

    /// @inheritdoc ICyberEngine
    function getContentCount(
        address account
    ) external view override returns (uint256) {
        return _accounts[account].contentCount;
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
    function getContentMw(
        address account,
        uint256 tokenID
    ) external view override returns (address) {
        _requireContentRegistered(account, tokenID);
        return _contentByIdByAccount[account][tokenID].mw;
    }

    /// @inheritdoc ICyberEngine
    function getW3stAddr(
        address account
    ) external view override returns (address) {
        return _accounts[account].w3st;
    }

    /// @inheritdoc ICyberEngine
    function getW3stCount(
        address account
    ) external view override returns (uint256) {
        return _accounts[account].w3stCount;
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

    /// @inheritdoc ICyberEngine
    function getW3stMw(
        address account,
        uint256 tokenID
    ) external view override returns (address) {
        _requireW3stRegistered(account, tokenID);
        return _w3stByIdByAccount[account][tokenID].mw;
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
            _accounts[account].contentCount > tokenId,
            "CONTENT_DOES_NOT_EXIST"
        );
    }

    function _requireW3stRegistered(
        address account,
        uint256 tokenId
    ) internal view {
        require(_accounts[account].w3stCount > tokenId, "W3ST_DOES_NOT_EXIST");
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
            tokenId = id;
        } else if (category == DataTypes.Category.Content) {
            IContent(deployAddr).mint(collector, id, amount, new bytes(0));
            tokenId = id;
        } else if (category == DataTypes.Category.Essence) {
            require(amount == 1, "INCORRECT_COLLECT_AMOUNT");
            tokenId = IEssence(deployAddr).mint(collector);
        } else {
            revert("WRONG_CATEGORY");
        }
    }

    function _getSrcIfShared(
        address account,
        uint256 id
    ) internal view returns (address srcAccount, uint256 srcId) {
        if (
            _contentByIdByAccount[account][id].contentType ==
            DataTypes.ContentType.Share
        ) {
            srcAccount = _contentByIdByAccount[account][id].srcAccount;
            srcId = _contentByIdByAccount[account][id].srcId;
        } else {
            srcAccount = account;
            srcId = id;
        }
    }
}
