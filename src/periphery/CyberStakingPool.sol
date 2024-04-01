// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { Pausable } from "openzeppelin-contracts/contracts/security/Pausable.sol";
import { EIP712 } from "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import { SignatureChecker } from "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { EIP712Signature } from "../interfaces/ICyberStakingPool.sol";
import { BridgeParams } from "../interfaces/ICyberStakingPool.sol";

import { IWETH } from "../interfaces/IWETH.sol";
import { IBridge } from "../interfaces/IBridge.sol";
import { ICyberStakingPool } from "../interfaces/ICyberStakingPool.sol";

/**
 * @title CyberStakingPool
 * @author CyberConnect
 */
contract CyberStakingPool is
    ICyberStakingPool,
    ReentrancyGuard,
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
            "bridge(address bridge,address recipient,address[] assets,uint256[] amounts,uint256 deadline,uint256 nonce)"
        );

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _weth, address owner) EIP712("CyberStakingPool", "1") {
        require(_weth != address(0), "ZERO_ADDRESS");
        require(owner != address(0), "ZERO_ADDRESS");
        weth = _weth;
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    /*//////////////////////////////////////////////////////////////
                                PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberStakingPool
    function deposit(
        address asset,
        uint256 amount
    ) external whenNotPaused nonReentrant {
        require(amount != 0, "ZERO_AMOUNT");
        require(assetWhitelist[asset], "ASSET_NOT_WHITELISTED");

        uint256 beforeTransfer = IERC20(asset).balanceOf(address(this));
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        uint256 afterTransfer = IERC20(asset).balanceOf(address(this));
        uint256 actualAmount = afterTransfer - beforeTransfer;

        balance[asset][msg.sender] += actualAmount;
        totalBalance[asset] += actualAmount;

        emit Deposit(_logId++, msg.sender, asset, actualAmount);
    }

    receive() external payable {
        depositETH();
    }

    /// @inheritdoc ICyberStakingPool
    function depositETH() public payable whenNotPaused nonReentrant {
        require(msg.value != 0, "ZERO_AMOUNT");

        balance[weth][msg.sender] += msg.value;
        totalBalance[weth] += msg.value;
        IWETH(weth).deposit{ value: msg.value }();

        emit Deposit(_logId++, msg.sender, weth, msg.value);
    }

    /// @inheritdoc ICyberStakingPool
    function withdraw(
        address[] calldata assets,
        uint256[] calldata amounts
    ) external nonReentrant {
        require(assets.length == amounts.length, "INVALID_LENGTH");
        for (uint256 i = 0; i < assets.length; i++) {
            address asset = assets[i];
            uint256 amount = amounts[i];
            require(amount != 0, "ZERO_AMOUNT");
            require(
                balance[asset][msg.sender] >= amount,
                "INSUFFICIENT_BALANCE"
            );

            balance[asset][msg.sender] -= amount;
            totalBalance[asset] -= amount;

            uint256 beforeTransfer = IERC20(asset).balanceOf(address(this));
            IERC20(asset).safeTransfer(msg.sender, amount);
            uint256 afterTransfer = IERC20(asset).balanceOf(address(this));
            require(
                beforeTransfer - afterTransfer == amount,
                "TRANSFER_FAILED"
            );
        }

        emit Withdraw(_logId++, msg.sender, assets, amounts);
    }

    /// @inheritdoc ICyberStakingPool
    function bridge(BridgeParams calldata params) external nonReentrant {
        require(
            params.assets.length == params.amounts.length,
            "INVALID_LENGTH"
        );
        require(
            bridgeWhitelist[params.bridgeAddress],
            "BRIDGE_NOT_WHITELISTED"
        );

        _bridge(
            params.bridgeAddress,
            msg.sender,
            params.recipient,
            params.assets,
            params.amounts
        );
    }

    /// @inheritdoc ICyberStakingPool
    function bridgeWithSig(
        address assetOwner,
        BridgeParams calldata params,
        EIP712Signature calldata signature
    ) external nonReentrant {
        require(
            bridgeWhitelist[params.bridgeAddress],
            "BRIDGE_NOT_WHITELISTED"
        );
        require(signature.deadline >= block.timestamp, "SIGNATURE_EXPIRED");
        {
            require(
                SignatureChecker.isValidSignatureNow(
                    assetOwner,
                    _hashTypedDataV4(
                        keccak256(
                            abi.encode(
                                BRIDGE_TYPEHASH,
                                params.bridgeAddress,
                                params.recipient,
                                keccak256(abi.encodePacked(params.assets)),
                                keccak256(abi.encodePacked(params.amounts)),
                                signature.deadline,
                                nonces[assetOwner]++
                            )
                        )
                    ),
                    signature.signature
                ),
                "INVALID_SIGNATURE"
            );
        }

        _bridge(
            params.bridgeAddress,
            assetOwner,
            params.recipient,
            params.assets,
            params.amounts
        );
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

    /**
     * @notice Pauses deposit.
     */
    function pause() external onlyRole(_OPERATOR_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses deposit.
     */
    function unpause() external onlyRole(_OPERATOR_ROLE) {
        _unpause();
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

    /*//////////////////////////////////////////////////////////////
                                PRIVATE
    //////////////////////////////////////////////////////////////*/

    function _bridge(
        address bridgeAddress,
        address assetOwner,
        address recipient,
        address[] calldata assets,
        uint256[] calldata amounts
    ) private {
        require(assetOwner != address(0), "ZERO_ADDRESS");
        uint256[] memory beforeAmounts = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            address asset = assets[i];
            uint256 amount = amounts[i];
            require(amount != 0, "ZERO_AMOUNT");
            require(
                balance[asset][assetOwner] >= amount,
                "INSUFFICIENT_BALANCE"
            );

            balance[asset][assetOwner] -= amount;
            totalBalance[asset] -= amount;

            bool success = IERC20(asset).approve(bridgeAddress, amount);
            require(success, "APPROVE_FAILED");
            beforeAmounts[i] = IERC20(asset).balanceOf(address(this));
        }

        IBridge(bridgeAddress).bridge(assetOwner, recipient, assets, amounts);

        for (uint256 i = 0; i < assets.length; i++) {
            uint256 afterAmount = IERC20(assets[i]).balanceOf(address(this));
            require(
                beforeAmounts[i] - afterAmount == amounts[i],
                "BRIDGE_FAILED"
            );
        }

        emit Bridge(
            _logId++,
            bridgeAddress,
            assetOwner,
            recipient,
            assets,
            amounts
        );
    }
}
