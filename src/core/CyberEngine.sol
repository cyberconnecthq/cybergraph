// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { Clones } from "openzeppelin-contracts/contracts/proxy/Clones.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { IMiddlewareManager } from "../interfaces/IMiddlewareManager.sol";
import { IMiddleware } from "../interfaces/IMiddleware.sol";
import { IEssence } from "../interfaces/IEssence.sol";
import { IContent } from "../interfaces/IContent.sol";
import { ISubscribe } from "../interfaces/ISubscribe.sol";
import { IW3st } from "../interfaces/IW3st.sol";
import { ISoul } from "../interfaces/ISoul.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

/**
 * @title CyberEngine
 * @author CyberConnect
 * @notice The core contract of the CyberConnect Protocol.
 * Address with a Soul token can create Content, Comment, Share, Essence and register Subscribe.
 * Address with a Org Soul token can issue W3st.
 * Any address can collect Content, Comment, Share, Essence, W3st and make a subscription.
 */
contract CyberEngine is
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuard,
    ICyberEngine
{
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    address public soul;
    address public manager;
    address public admin;

    address internal _essenceImpl;
    address internal _subscribeImpl;
    address internal _contentImpl;
    address internal _w3stImpl;

    mapping(address => mapping(uint256 => DataTypes.EssenceStruct))
        internal _essenceByIdByAccount;
    mapping(address => mapping(uint256 => DataTypes.ContentStruct))
        internal _contentByIdByAccount;
    mapping(address => mapping(uint256 => DataTypes.W3stStruct))
        internal _w3stByIdByAccount;
    mapping(address => DataTypes.SubscribeStruct) internal _subscribeByAccount;
    mapping(address => DataTypes.AccountStruct) internal _accounts;
    mapping(address => mapping(address => bool)) internal _operatorApproval;

    uint256 internal constant _VERSION = 1;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks the account is a soul owner.
     */
    modifier onlySoulOwner() {
        require(IERC721(soul).balanceOf(msg.sender) > 0, "ONLY_SOUL_OWNER");
        _;
    }

    /**
     * @notice Checks the account is a soul owner or operator.
     */
    modifier onlySoulOwnerOrOperator(address account) {
        require(IERC721(soul).balanceOf(account) > 0, "ONLY_SOUL_OWNER");
        require(
            msg.sender == account || getOperatorApproval(account, msg.sender),
            "ONLY_OWNER_OR_OPERATOR"
        );
        _;
    }

    /**
     * @notice Checks the account is an org owner or operator.
     */
    modifier onlyOrgOwnerOrOperator(address account) {
        require(ISoul(soul).isOrgAccount(account), "ONLY_ORG_ACCOUNT");
        require(
            msg.sender == account || getOperatorApproval(account, msg.sender),
            "ONLY_OWNER_OR_OPERATOR"
        );
        _;
    }

    /**
     * @notice Checks if the sender is authorized to upgrade the contract.
     */
    modifier canUpgrade() {
        require(msg.sender == admin, "UNAUTHORIZED");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberEngine
    function initialize(
        DataTypes.InitParams calldata params
    ) external override initializer {
        require(params.soulAddr != address(0), "SOUL_NOT_SET");
        require(params.mwManagerAddr != address(0), "MW_MANAGER_NOT_SET");
        require(params.essImpl != address(0), "ESS_IMPL_NOT_SET");
        require(params.contentImpl != address(0), "CONTENT_IMPL_NOT_SET");
        require(params.w3stImpl != address(0), "W3ST_IMPL_NOT_SET");
        require(params.subImpl != address(0), "SUB_IMPL_NOT_SET");
        require(params.adminAddr != address(0), "ADMIN_NOT_SET");

        soul = params.soulAddr;
        manager = params.mwManagerAddr;
        admin = params.adminAddr;

        _essenceImpl = params.essImpl;
        _contentImpl = params.contentImpl;
        _w3stImpl = params.w3stImpl;
        _subscribeImpl = params.subImpl;

        emit Initialize(
            soul,
            manager,
            _essenceImpl,
            _contentImpl,
            _w3stImpl,
            _subscribeImpl,
            admin
        );
    }

    /// @inheritdoc ICyberEngine
    function collect(
        DataTypes.CollectParams calldata params,
        bytes calldata data
    ) external override nonReentrant returns (uint256 tokenId) {
        address from = msg.sender;
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
                IMiddlewareManager(manager).isMwAllowed(mw),
                "MW_NOT_ALLOWED"
            );
            IMiddleware(mw).preProcess(
                DataTypes.MwParams(
                    account,
                    params.category,
                    id,
                    params.amount,
                    from,
                    params.to,
                    params.account,
                    data
                )
            );
        }

        tokenId = _mintNFT(
            deployAddr,
            params.to,
            id,
            params.amount,
            params.category
        );
        emit Collect(
            params.to,
            from,
            params.account,
            params.id,
            params.amount,
            tokenId,
            params.category
        );
    }

    /// @inheritdoc ICyberEngine
    function subscribe(
        address account,
        address to
    ) external payable override returns (uint256 tokenId) {
        address from = msg.sender;

        _requireSubscriptionRegistered(account);

        address deployAddr = _subscribeByAccount[account].subscribe;
        uint256 numOfSub = msg.value / _subscribeByAccount[account].pricePerSub;

        require(numOfSub >= 1, "FEE_NOT_ENOUGH");

        _chargeAndRefundOverPayment(
            _subscribeByAccount[account].recipient,
            numOfSub * _subscribeByAccount[account].pricePerSub,
            from
        );

        if (IERC721(deployAddr).balanceOf(to) == 0) {
            tokenId = ISubscribe(deployAddr).mint(
                to,
                numOfSub * _subscribeByAccount[account].dayPerSub
            );
        } else {
            tokenId = ISubscribe(deployAddr).extend(
                to,
                numOfSub * _subscribeByAccount[account].dayPerSub
            );
        }
    }

    /// @inheritdoc ICyberEngine
    function registerEssence(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData
    )
        external
        override
        onlySoulOwnerOrOperator(params.account)
        returns (uint256 id)
    {
        require(
            params.mw == address(0) ||
                IMiddlewareManager(manager).isMwAllowed(params.mw),
            "MW_NOT_ALLOWED"
        );

        require(bytes(params.name).length != 0, "EMPTY_NAME");
        require(bytes(params.symbol).length != 0, "EMPTY_SYMBOL");

        id = _accounts[params.account].essenceCount;

        _essenceByIdByAccount[params.account][id].name = params.name;
        _essenceByIdByAccount[params.account][id].symbol = params.symbol;
        _essenceByIdByAccount[params.account][id].tokenURI = params.tokenURI;
        _essenceByIdByAccount[params.account][id].transferable = params
            .transferable;

        if (params.mw != address(0)) {
            _essenceByIdByAccount[params.account][id].mw = params.mw;
            IMiddleware(params.mw).setMwData(
                params.account,
                DataTypes.Category.Essence,
                id,
                initData
            );
        }

        address essence = Clones.clone(_essenceImpl);
        IEssence(essence).initialize(
            params.account,
            id,
            params.name,
            params.symbol,
            params.transferable
        );
        _essenceByIdByAccount[params.account][id].essence = essence;
        ++_accounts[params.account].essenceCount;

        emit RegisterEssence(
            params.account,
            id,
            params.name,
            params.symbol,
            params.tokenURI,
            params.transferable,
            params.mw,
            essence
        );
    }

    /// @inheritdoc ICyberEngine
    function registerSubscription(
        DataTypes.RegisterSubscriptionParams calldata params
    ) external override onlySoulOwnerOrOperator(params.account) {
        require(
            _subscribeByAccount[params.account].subscribe == address(0),
            "ALREADY_REGISTERED"
        );
        require(bytes(params.name).length != 0, "EMPTY_NAME");
        require(bytes(params.symbol).length != 0, "EMPTY_SYMBOL");
        require(params.pricePerSub > 0, "INVALID_PRICE_PER_SUB");
        require(params.dayPerSub > 0, "INVALID_DAY_PER_SUB");
        require(params.recipient != address(0), "ZERO_RECIPIENT_ADDRESS");

        _subscribeByAccount[params.account].name = params.name;
        _subscribeByAccount[params.account].symbol = params.symbol;
        _subscribeByAccount[params.account].tokenURI = params.tokenURI;
        _subscribeByAccount[params.account].pricePerSub = params.pricePerSub;
        _subscribeByAccount[params.account].dayPerSub = params.dayPerSub;
        _subscribeByAccount[params.account].recipient = params.recipient;

        address deployedSubscribe = Clones.clone(_subscribeImpl);
        ISubscribe(deployedSubscribe).initialize(
            params.account,
            params.name,
            params.symbol
        );

        _subscribeByAccount[params.account].subscribe = deployedSubscribe;

        emit RegisterSubscription(
            params.account,
            params.name,
            params.symbol,
            params.tokenURI,
            params.pricePerSub,
            params.dayPerSub,
            params.recipient,
            deployedSubscribe
        );
    }

    /// @inheritdoc ICyberEngine
    function publishContent(
        DataTypes.PublishContentParams calldata params,
        bytes calldata initData
    )
        external
        override
        onlySoulOwnerOrOperator(params.account)
        returns (uint256)
    {
        require(
            params.mw == address(0) ||
                IMiddlewareManager(manager).isMwAllowed(params.mw),
            "MW_NOT_ALLOWED"
        );

        address account = params.account;
        uint256 tokenId = _accounts[account].contentCount;

        // deploy the contract for the first time
        if (tokenId == 0) {
            address content = Clones.clone(_contentImpl);
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
            params.transferable,
            params.mw,
            _accounts[account].content
        );
        return tokenId;
    }

    /// @inheritdoc ICyberEngine
    function share(
        DataTypes.ShareParams calldata params
    )
        external
        override
        onlySoulOwnerOrOperator(params.account)
        returns (uint256)
    {
        _requireContentRegistered(params.accountShared, params.idShared);

        (address srcAccount, uint256 srcId) = _getSrcIfShared(
            params.accountShared,
            params.idShared
        );
        address account = params.account;
        uint256 tokenId = _accounts[account].contentCount;

        // deploy the contract for the first time
        if (tokenId == 0) {
            address content = Clones.clone(_contentImpl);
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
    )
        external
        override
        onlySoulOwnerOrOperator(params.account)
        returns (uint256)
    {
        require(
            params.mw == address(0) ||
                IMiddlewareManager(manager).isMwAllowed(params.mw),
            "MW_NOT_ALLOWED"
        );

        _requireContentRegistered(params.accountCommented, params.idCommented);

        address account = params.account;
        uint256 tokenId = _accounts[account].contentCount;

        // deploy the contract for the first time
        if (tokenId == 0) {
            address content = Clones.clone(_contentImpl);
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
            params.transferable,
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
    )
        external
        override
        onlyOrgOwnerOrOperator(params.account)
        returns (uint256)
    {
        require(
            params.mw == address(0) ||
                IMiddlewareManager(manager).isMwAllowed(params.mw),
            "MW_NOT_ALLOWED"
        );

        address account = params.account;
        uint256 tokenId = _accounts[account].w3stCount;

        // deploy the contract for the first time
        if (tokenId == 0) {
            address w3st = Clones.clone(_w3stImpl);
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
            params.transferable,
            params.mw,
            _accounts[account].w3st
        );
        return tokenId;
    }

    /// @inheritdoc ICyberEngine
    function setEssenceData(
        address account,
        uint256 essenceId,
        string calldata uri,
        address mw,
        bytes calldata data
    ) external override onlySoulOwnerOrOperator(account) {
        require(
            mw == address(0) || IMiddlewareManager(manager).isMwAllowed(mw),
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
    function setSubscriptionData(
        address account,
        string calldata uri,
        address recipient,
        uint256 pricePerSub,
        uint256 dayPerSub
    ) external override onlySoulOwnerOrOperator(account) {
        _requireSubscriptionRegistered(account);

        _subscribeByAccount[account].tokenURI = uri;
        _subscribeByAccount[account].recipient = recipient;
        _subscribeByAccount[account].pricePerSub = pricePerSub;
        _subscribeByAccount[account].dayPerSub = dayPerSub;

        emit SetSubscriptionData(
            account,
            uri,
            recipient,
            pricePerSub,
            dayPerSub
        );
    }

    /// @inheritdoc ICyberEngine
    function setContentData(
        address account,
        uint256 tokenId,
        string calldata uri,
        address mw,
        bytes calldata data
    ) external override onlySoulOwnerOrOperator(account) {
        require(
            mw == address(0) || IMiddlewareManager(manager).isMwAllowed(mw),
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
        address account,
        uint256 tokenId,
        string calldata uri,
        address mw,
        bytes calldata data
    ) external override onlySoulOwnerOrOperator(account) {
        require(
            mw == address(0) || IMiddlewareManager(manager).isMwAllowed(mw),
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

    /// @inheritdoc ICyberEngine
    function setOperatorApproval(
        address operator,
        bool approved
    ) external override onlySoulOwner {
        require(operator != address(0), "ZERO_ADDRESS");
        bool prev = _operatorApproval[msg.sender][operator];
        _operatorApproval[msg.sender][operator] = approved;

        emit SetOperatorApproval(msg.sender, operator, prev, approved);
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
        uint256 tokenId
    ) external view override returns (string memory) {
        _requireContentRegistered(account, tokenId);
        (address srcAccount, uint256 srcId) = _getSrcIfShared(account, tokenId);
        return _contentByIdByAccount[srcAccount][srcId].tokenURI;
    }

    /// @inheritdoc ICyberEngine
    function getContentSrcInfo(
        address account,
        uint256 tokenId
    ) external view override returns (address, uint256) {
        _requireContentRegistered(account, tokenId);
        return (
            _contentByIdByAccount[account][tokenId].srcAccount,
            _contentByIdByAccount[account][tokenId].srcId
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
        uint256 tokenId
    ) external view override returns (bool) {
        _requireContentRegistered(account, tokenId);
        return _contentByIdByAccount[account][tokenId].transferable;
    }

    /// @inheritdoc ICyberEngine
    function getContentMw(
        address account,
        uint256 tokenId
    ) external view override returns (address) {
        _requireContentRegistered(account, tokenId);
        return _contentByIdByAccount[account][tokenId].mw;
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
        uint256 tokenId
    ) external view override returns (string memory) {
        _requireW3stRegistered(account, tokenId);
        return _w3stByIdByAccount[account][tokenId].tokenURI;
    }

    /// @inheritdoc ICyberEngine
    function getW3stTransferability(
        address account,
        uint256 tokenId
    ) external view override returns (bool) {
        _requireW3stRegistered(account, tokenId);
        return _w3stByIdByAccount[account][tokenId].transferable;
    }

    /// @inheritdoc ICyberEngine
    function getW3stMw(
        address account,
        uint256 tokenId
    ) external view override returns (address) {
        _requireW3stRegistered(account, tokenId);
        return _w3stByIdByAccount[account][tokenId].mw;
    }

    /// @inheritdoc ICyberEngine
    function getSubscriptionTokenURI(
        address account
    ) external view override returns (string memory) {
        _requireSubscriptionRegistered(account);
        return _subscribeByAccount[account].tokenURI;
    }

    /// @inheritdoc ICyberEngine
    function getSubscriptionRecipient(
        address account
    ) external view override returns (address) {
        _requireSubscriptionRegistered(account);
        return _subscribeByAccount[account].recipient;
    }

    /// @inheritdoc ICyberEngine
    function getSubscriptionPricePerSub(
        address account
    ) external view override returns (uint256) {
        _requireSubscriptionRegistered(account);
        return _subscribeByAccount[account].pricePerSub;
    }

    /// @inheritdoc ICyberEngine
    function getSubscriptionDayPerSub(
        address account
    ) external view override returns (uint256) {
        _requireSubscriptionRegistered(account);
        return _subscribeByAccount[account].dayPerSub;
    }

    /// @inheritdoc ICyberEngine
    function getSubscriptionAddr(
        address account
    ) external view returns (address) {
        _requireSubscriptionRegistered(account);
        return _subscribeByAccount[account].subscribe;
    }

    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberEngine
    function getOperatorApproval(
        address account,
        address operator
    ) public view returns (bool) {
        return _operatorApproval[account][operator];
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

    function _requireSubscriptionRegistered(address account) internal view {
        require(
            _subscribeByAccount[account].subscribe != address(0),
            "SUBSCRIBE_DOES_NOT_EXIST"
        );
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
        address to,
        uint256 id,
        uint256 amount,
        DataTypes.Category category
    ) internal returns (uint256 tokenId) {
        if (category == DataTypes.Category.W3ST) {
            IW3st(deployAddr).mint(to, id, amount, new bytes(0));
            tokenId = id;
        } else if (category == DataTypes.Category.Content) {
            IContent(deployAddr).mint(to, id, amount, new bytes(0));
            tokenId = id;
        } else if (category == DataTypes.Category.Essence) {
            require(amount == 1, "INCORRECT_COLLECT_AMOUNT");
            tokenId = IEssence(deployAddr).mint(to);
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

    function _chargeAndRefundOverPayment(
        address recipient,
        uint256 cost,
        address refundTo
    ) internal {
        uint256 overpayment;
        unchecked {
            overpayment = msg.value - cost;
        }

        if (overpayment > 0) {
            (bool refundSuccess, ) = refundTo.call{ value: overpayment }("");
            require(refundSuccess, "REFUND_FAILED");
        }
        (bool chargeSuccess, ) = recipient.call{ value: cost }("");
        require(chargeSuccess, "CHARGE_FAILED");
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override canUpgrade {}
}
