// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { Pausable } from "openzeppelin-contracts/contracts/security/Pausable.sol";
import { EIP712 } from "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import { SignatureChecker } from "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";

import { IWETH } from "../interfaces/IWETH.sol";
import { IBridge } from "../interfaces/IBridge.sol";
import { ICyberStakingPool } from "../interfaces/ICyberStakingPool.sol";

/**
 * @title CyberStakingPool
 * @author CyberConnect
 */
contract CyberStakingPool is
    ICyberStakingPool,
    AccessControl,
    Pausable,
    EIP712
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    address public immutable weth;
    // asset => isWhitelisted
    mapping(address => bool) public assetWhitelist;
    // bridge => isWhitelisted
    mapping(address => bool) public bridgeWhitelist;
    // asset => user => balance
    mapping(address => mapping(address => uint256)) public balance;
    // asset => total balance
    mapping(address => uint256) public totalBalance;
    // asset owner => nonce
    mapping(address => uint256) public nonces;

    bytes32 internal constant _OPERATOR_ROLE =
        keccak256(bytes("OPERATOR_ROLE"));

    uint256 private _logId;

    bytes32 private constant BRIDGE_TYPEHASH =
        keccak256(
            "bridge(address bridge,address assetOwner,address receipient,address asset,uint256 amount,uint256 deadline,uint256 nonce)"
        );

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _weth, address owner) EIP712("CyberStakingPool", "1") {
        weth = _weth;
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    /*//////////////////////////////////////////////////////////////
                                PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberStakingPool
    function deposit(address asset, uint256 amount) external {
        depositFor(msg.sender, asset, amount);
    }

    /// @inheritdoc ICyberStakingPool
    function depositFor(
        address to,
        address asset,
        uint256 amount
    ) public whenNotPaused {
        require(amount != 0, "ZERO_AMOUNT");
        require(assetWhitelist[asset], "ASSET_NOT_WHITELISTED");

        uint256 beforeTransfer = IERC20(asset).balanceOf(address(this));
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        uint256 afterTransfer = IERC20(asset).balanceOf(address(this));
        uint256 actualAmount = afterTransfer - beforeTransfer;

        balance[asset][to] += actualAmount;
        totalBalance[asset] += actualAmount;

        emit Deposit(_logId++, to, asset, actualAmount);
    }

    receive() external payable {
        depositETHFor(msg.sender);
    }

    /// @inheritdoc ICyberStakingPool
    function depositETH() external payable {
        depositETHFor(msg.sender);
    }

    /// @inheritdoc ICyberStakingPool
    function depositETHFor(address to) public payable whenNotPaused {
        require(msg.value != 0, "ZERO_AMOUNT");

        balance[weth][to] += msg.value;
        totalBalance[weth] += msg.value;
        IWETH(weth).deposit{ value: msg.value }();

        emit Deposit(_logId++, to, weth, msg.value);
    }

    /// @inheritdoc ICyberStakingPool
    function withdraw(
        address receipient,
        address asset,
        uint256 amount
    ) external {
        require(amount != 0, "ZERO_AMOUNT");
        require(balance[asset][msg.sender] >= amount, "INSUFFICIENT_BALANCE");

        balance[asset][msg.sender] -= amount;
        totalBalance[asset] -= amount;

        IERC20(asset).safeTransfer(receipient, amount);
        emit Withdraw(_logId++, msg.sender, receipient, asset, amount);
    }

    /// @inheritdoc ICyberStakingPool
    function bridge(
        address bridgeAddress,
        address receipient,
        address asset,
        uint256 amount
    ) external {
        require(amount != 0, "ZERO_AMOUNT");
        require(bridgeWhitelist[bridgeAddress], "BRIDGE_NOT_WHITELISTED");
        require(balance[asset][msg.sender] >= amount, "INSUFFICIENT_BALANCE");

        _bridge(bridgeAddress, msg.sender, receipient, asset, amount);
    }

    /// @inheritdoc ICyberStakingPool
    function bridgeWithSig(
        address bridgeAddress,
        address assetOwner,
        address receipient,
        address asset,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external {
        require(amount != 0, "ZERO_AMOUNT");
        require(bridgeWhitelist[bridgeAddress], "BRIDGE_NOT_WHITELISTED");
        require(balance[asset][assetOwner] >= amount, "INSUFFICIENT_BALANCE");

        {
            require(deadline >= block.timestamp, "SIGNATURE_EXPIRED");
            bytes32 structHash = keccak256(
                abi.encode(
                    BRIDGE_TYPEHASH,
                    bridgeAddress,
                    assetOwner,
                    receipient,
                    asset,
                    amount,
                    deadline,
                    nonces[assetOwner]++
                )
            );
            bytes32 constructedHash = _hashTypedDataV4(structHash);

            bool valid = SignatureChecker.isValidSignatureNow(
                assetOwner,
                constructedHash,
                signature
            );
            require(valid, "INVALID_SIGNATURE");
        }

        _bridge(bridgeAddress, assetOwner, receipient, asset, amount);
    }

    /*//////////////////////////////////////////////////////////////
                                OPERATOR
    //////////////////////////////////////////////////////////////*/

    function setAssetWhitelist(
        address asset,
        bool isWhitelisted
    ) external onlyRole(_OPERATOR_ROLE) {
        require(asset != address(0), "ZERO_ADDRESS");
        require(assetWhitelist[asset] != isWhitelisted, "SAME_VALUE");
        assetWhitelist[asset] = isWhitelisted;
        emit SetAssetWhitelist(asset, isWhitelisted);
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set bridge whitelist.
     *
     * @param bridgeAddress The bridge address.
     * @param isWhitelisted The whitelist status.
     */
    function setBridgeWhitelist(
        address bridgeAddress,
        bool isWhitelisted
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bridgeAddress != address(0), "ZERO_ADDRESS");
        require(bridgeWhitelist[bridgeAddress] != isWhitelisted, "SAME_VALUE");
        bridgeWhitelist[bridgeAddress] = isWhitelisted;
        emit SetBridgeWhitelist(bridgeAddress, isWhitelisted);
    }

    /**
     * @notice Pauses deposit.
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses deposit.
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                                PRIVATE
    //////////////////////////////////////////////////////////////*/

    function _bridge(
        address bridgeAddress,
        address assetOwner,
        address receipient,
        address asset,
        uint256 amount
    ) private {
        balance[asset][assetOwner] -= amount;
        totalBalance[asset] -= amount;

        IERC20(asset).approve(bridgeAddress, amount);
        IBridge(bridgeAddress).bridge(assetOwner, receipient, asset, amount);

        emit Bridge(
            _logId++,
            bridgeAddress,
            assetOwner,
            receipient,
            asset,
            amount
        );
    }
}
