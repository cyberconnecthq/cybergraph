// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Permit } from "openzeppelin-contracts/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "universal-router/contracts/interfaces/IUniversalRouter.sol";
import { Commands as UniswapCommands } from "universal-router/contracts/libraries/Commands.sol";
import { Constants as UniswapConstants } from "universal-router/contracts/libraries/Constants.sol";
import "../interfaces/ICyberVault.sol";

/**
 * @title CyberVaultV3
 * @author CyberConnect
 * @notice This contract is used to create deposit and distribute tokens.
 */
contract CyberVaultV3 is
    Initializable,
    AccessControl,
    UUPSUpgradeable,
    ReentrancyGuard,
    ICyberVault
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            V1 STORAGE
    //////////////////////////////////////////////////////////////*/
    address public receipient;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public balancesByCurrency;

    bytes32 internal constant _OPERATOR_ROLE =
        keccak256(bytes("OPERATOR_ROLE"));

    /*//////////////////////////////////////////////////////////////
                            V2 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public balance;
    mapping(address => uint256) public erc20balances;

    /*//////////////////////////////////////////////////////////////
                            V3 STORAGE
    //////////////////////////////////////////////////////////////*/

    // Represents native token of a chain (e.g. ETH or MATIC)
    address private immutable _NATIVE_CURRENCY = address(0);
    // Canonical wrapped token for this chain. e.g. (wETH or wMATIC).
    address private immutable _wrappedNativeCurrency;
    // Uniswap on-chain contract
    IUniversalRouter private immutable _uniswap;
    // The swap tokenIn whitelist
    mapping(address => bool) public tokenInWhitelist;
    // The currency that the recipient wants to receive (e.g. USDT)
    address public recipientCurrency;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    // @param recipientCurrency The currency that the recipient wants to receive
    // @param uniswap The address of the Uniswap V3 swap router
    // @param wrappedNativeCurrency The address of the wrapped token for this chain
    constructor(
        address recipientCurrency,
        IUniversalRouter uniswap,
        address wrappedNativeCurrency
    ) {
        require(
            address(recipientCurrency) != address(0) &&
                address(uniswap) != address(0) &&
                address(wrappedNativeCurrency) != address(0),
            "invalid constructor parameters"
        );
        recipientCurrency = recipientCurrency;
        _uniswap = uniswap;
        _wrappedNativeCurrency = wrappedNativeCurrency;
        // _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function depositPreApprove(
        address depositTo,
        uint256 amount
    ) external nonReentrant {
        IERC20 token = IERC20(recipientCurrency);
        // Make sure the payer has enough of the payment token
        uint256 payerBalance = token.balanceOf(msg.sender);
        if (payerBalance < amount) {
            revert InsufficientBalance(amount - payerBalance);
        }

        // Make sure the payer has approved this contract for a sufficient transfer
        uint256 allowance = token.allowance(msg.sender, address(this));
        if (allowance < amount) {
            revert InsufficientAllowance(amount - allowance);
        }

        // Perform and complete the deposit
        token.safeTransferFrom(msg.sender, address(this), amount);
        _succeedDeposit(depositTo, amount);
    }

    function depositWithPermit(
        address depositTo,
        ERC20PermitData calldata _permit
    ) external nonReentrant {
        require(_permit.currency == recipientCurrency, "INVALID_CURRENCY");

        // Make sure the payer has enough of the payment token
        uint256 payerBalance = IERC20(recipientCurrency).balanceOf(msg.sender);
        if (payerBalance < _permit.amount) {
            revert InsufficientBalance(_permit.amount - payerBalance);
        }

        // Permit the token transfer
        try
            IERC20Permit(recipientCurrency).permit(
                msg.sender,
                address(this),
                _permit.amount,
                _permit.deadline,
                _permit.v,
                _permit.r,
                _permit.s
            )
        {} catch {
            revert InvalidPermitSignature();
        }

        // Perform and complete the deposit
        IERC20(recipientCurrency).safeTransferFrom(
            msg.sender,
            address(this),
            _permit.amount
        );
        _succeedDeposit(depositTo, _permit.amount);
    }

    function swapNativeAndDeposit(
        address depositTo,
        SwapIntent calldata _intent
    ) external payable nonReentrant validSwapIntent(_intent) {
        require(_intent.tokenInAmount == msg.value, "AMOUNT_MISMATCH");
        require(_intent.tokenIn == _wrappedNativeCurrency, "INVALID_TOKEN_IN");

        // Perform the swap
        uint256 amountSwapped = _swapTokens(_intent);

        // Complete the deposit
        _succeedDeposit(depositTo, amountSwapped);
    }

    function swapERC20PreApproveAndDeposit(
        address depositTo,
        SwapIntent calldata _intent
    ) external nonReentrant validSwapIntent(_intent) {
        IERC20 tokenIn = IERC20(_intent.tokenIn);
        // Make sure the payer has enough of the payment token
        uint256 payerBalance = tokenIn.balanceOf(msg.sender);
        if (payerBalance < _intent.tokenInAmount) {
            revert InsufficientBalance(_intent.tokenInAmount - payerBalance);
        }

        // Make sure the payer has approved this contract for a sufficient transfer
        uint256 allowance = tokenIn.allowance(msg.sender, address(this));
        if (allowance < _intent.tokenInAmount) {
            revert InsufficientAllowance(_intent.tokenInAmount - allowance);
        }

        // Transfer the payment token to this contract
        tokenIn.safeTransferFrom(
            msg.sender,
            address(this),
            _intent.tokenInAmount
        );

        // Perform the swap
        uint256 amountSwapped = _swapTokens(_intent);

        // Complete the deposit
        _succeedDeposit(depositTo, amountSwapped);
    }

    function swapERC20WithPermitAndDeposit(
        address depositTo,
        SwapIntent calldata _intent,
        ERC20PermitData calldata _permit
    ) external nonReentrant validSwapIntent(_intent) {
        require(_intent.tokenInAmount == _permit.amount, "AMOUNT_MISMATCH");
        require(_intent.tokenIn == _permit.currency, "INVALID_TOKEN_IN");

        // Make sure the payer has enough of the payment token
        uint256 payerBalance = IERC20(_intent.tokenIn).balanceOf(msg.sender);
        if (payerBalance < _intent.tokenInAmount) {
            revert InsufficientBalance(_intent.tokenInAmount - payerBalance);
        }

        uint256 amountSwapped = 0;
        // Permit the token transfer
        try
            IERC20Permit(_intent.tokenIn).permit(
                msg.sender,
                address(this),
                _permit.amount,
                _permit.deadline,
                _permit.v,
                _permit.r,
                _permit.s
            )
        {} catch {
            revert InvalidPermitSignature();
        }
        // Transfer the payment token to this contract
        IERC20(_intent.tokenIn).safeTransferFrom(
            msg.sender,
            address(this),
            _permit.amount
        );
        // Perform the swap
        amountSwapped = _swapTokens(_intent);
        // Complete the deposit
        _succeedDeposit(depositTo, amountSwapped);
    }

    /*//////////////////////////////////////////////////////////////
                            ONLY OPERATOR
    //////////////////////////////////////////////////////////////*/

    function withdraw(
        address to,
        uint256 amount
    ) external onlyRole(_OPERATOR_ROLE) {
        (bool success, ) = to.call{ value: amount }("");
        require(success, "WITHDRAW_FAILED");
        emit Withdraw(to, amount);
    }

    function withdrawERC20(
        address to,
        address currency,
        uint256 amount
    ) external onlyRole(_OPERATOR_ROLE) {
        IERC20(currency).safeTransfer(to, amount);
        emit WithdrawERC20(to, currency, amount);
    }

    function migrateBalance(uint256 amount) external onlyRole(_OPERATOR_ROLE) {
        balance = amount;
    }

    function migrateERC20Balance(
        address currency,
        uint256 amount
    ) external onlyRole(_OPERATOR_ROLE) {
        erc20balances[currency] = amount;
    }

    function modifyRecipientCurrency(
        address currency
    ) external onlyRole(_OPERATOR_ROLE) {
        recipientCurrency = currency;
    }

    function setTokenInApproval(
        address currency,
        bool approved
    ) external onlyRole(_OPERATOR_ROLE) {
        tokenInWhitelist[currency] = approved;
    }

    /*//////////////////////////////////////////////////////////////
                            ONLY OWNER
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address) internal view override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _succeedDeposit(address depositTo, uint256 amount) internal {
        if (amount > 0) {
            erc20balances[recipientCurrency] += amount;
            emit Deposit(depositTo, amount);
        }
    }

    function _swapTokens(
        SwapIntent calldata _intent
    ) internal returns (uint256) {
        // Parameters and shared inputs for the universal router
        bytes memory uniswapCommands;
        bytes[] memory uniswapInputs;
        bytes memory swapPath = abi.encodePacked(
            _intent.tokenOut,
            _intent.poolFeesTier,
            _intent.tokenIn
        );
        bytes memory swapParams = abi.encode(
            address(_uniswap),
            _intent.tokenOutAmount,
            _intent.tokenInAmount,
            swapPath,
            false
        );
        uint256 deadline = _intent.deadline;
        bytes memory transferToRecipient = abi.encode(
            _intent.tokenOut,
            _intent.recipient,
            _intent.tokenOutAmount
        );
        IERC20 _tokenIn = IERC20(_intent.tokenIn);
        IERC20 _tokenOut = IERC20(_intent.tokenOut);

        // The payer's and router's balances before this transaction, used to calculate the amount consumed by the swap
        uint256 payerBalanceBefore;
        uint256 routerBalanceBefore;
        uint256 recipientBalanceBefore;

        // Populate the commands and inputs for the universal router
        if (msg.value > 0) {
            // Paying with ETH
            payerBalanceBefore = msg.sender.balance + msg.value;
            routerBalanceBefore =
                address(_uniswap).balance +
                IERC20(_wrappedNativeCurrency).balanceOf(address(_uniswap));
            recipientBalanceBefore = _tokenOut.balanceOf(_intent.recipient);

            // Paying with ETH, wrapping it to WETH, then swapping it for the output token
            uniswapCommands = abi.encodePacked(
                bytes1(uint8(UniswapCommands.WRAP_ETH)), // wrap ETH to WETH
                bytes1(uint8(UniswapCommands.V3_SWAP_EXACT_OUT)), // swap WETH for tokenOut
                bytes1(uint8(UniswapCommands.TRANSFER)), // transfer tokenOut to recipient
                bytes1(uint8(UniswapCommands.UNWRAP_WETH)), // unwrap WETH to ETH for the payer refund (if any left)
                bytes1(uint8(UniswapCommands.SWEEP)) // sweep any remaining ETH to the payer
            );
            uniswapInputs = new bytes[](5);
            uniswapInputs[0] = abi.encode(address(_uniswap), msg.value);
            uniswapInputs[1] = swapParams;
            uniswapInputs[2] = transferToRecipient;
            uniswapInputs[3] = abi.encode(address(_uniswap), 0);
            uniswapInputs[4] = abi.encode(UniswapConstants.ETH, msg.sender, 0);
        } else {
            // Paying with tokenIn (ERC20)
            // No need to check recipient balance of the output token before,
            // since we know WETH and ETH are not fee-on-transfer
            payerBalanceBefore =
                _tokenIn.balanceOf(msg.sender) +
                _intent.tokenInAmount;
            routerBalanceBefore = _tokenIn.balanceOf(address(_uniswap));
            recipientBalanceBefore = _tokenOut.balanceOf(_intent.recipient);

            // Paying with tokenIn, recipient wants tokenOut
            uniswapCommands = abi.encodePacked(
                bytes1(uint8(UniswapCommands.V3_SWAP_EXACT_OUT)), // swap tokenIn for tokenOut
                bytes1(uint8(UniswapCommands.TRANSFER)), // transfer tokenOut to recipient
                bytes1(uint8(UniswapCommands.SWEEP)) // sweep any remaining tokenIn to the payer
            );
            uniswapInputs = new bytes[](3);
            uniswapInputs[0] = swapParams;
            uniswapInputs[1] = transferToRecipient;
            uniswapInputs[2] = abi.encode(_intent.tokenIn, msg.sender, 0);

            // Send the input tokens to Uniswap for the swap
            _tokenIn.safeTransfer(address(_uniswap), _intent.tokenInAmount);
        }

        // Perform the swap
        try
            _uniswap.execute{ value: msg.value }(
                uniswapCommands,
                uniswapInputs,
                deadline
            )
        {
            // Calculate and return how much of the input token was consumed by the swap. The router
            // could have had a balance of the input token prior to this transaction, which would have
            // been swept to the payer. This amount, if any, must be accounted for so we don't underflow
            // and assume that negative amount of the input token was consumed by the swap.
            uint256 payerBalanceAfter;
            uint256 routerBalanceAfter;
            if (msg.value > 0) {
                payerBalanceAfter = msg.sender.balance;
                routerBalanceAfter =
                    address(_uniswap).balance +
                    IERC20(_wrappedNativeCurrency).balanceOf(address(_uniswap));
            } else {
                payerBalanceAfter = _tokenIn.balanceOf(msg.sender);
                routerBalanceAfter = _tokenIn.balanceOf(address(_uniswap));
            }
            return
                (payerBalanceBefore + routerBalanceBefore) -
                (payerBalanceAfter + routerBalanceAfter);
        } catch Error(string memory reason) {
            revert SwapFailedString(reason);
        } catch (bytes memory reason) {
            bytes32 reasonHash = keccak256(reason);
            if (reasonHash == V3_INVALID_SWAP) {
                revert SwapFailedString("V3InvalidSwap");
            } else if (reasonHash == V3_TOO_LITTLE_RECEIVED) {
                revert SwapFailedString("V3TooLittleReceived");
            } else if (reasonHash == V3_TOO_MUCH_REQUESTED) {
                revert SwapFailedString("V3TooMuchRequested");
            } else if (reasonHash == V3_INVALID_AMOUNT_OUT) {
                revert SwapFailedString("V3InvalidAmountOut");
            } else if (reasonHash == V3_INVALID_CALLER) {
                revert SwapFailedString("V3InvalidCaller");
            } else {
                revert SwapFailedBytes(reason);
            }
        }
    }

    function _revertIfInexactTransfer(
        uint256 expectedDiff,
        uint256 balanceBefore,
        IERC20 token,
        address target
    ) internal view {
        uint256 balanceAfter = token.balanceOf(target);
        if (balanceAfter - balanceBefore != expectedDiff) {
            revert InexactTransfer();
        }
    }

    // @dev Raises errors if the SwapIntent is invalid
    modifier validSwapIntent(SwapIntent calldata _intent) {
        if (_intent.deadline < block.timestamp) {
            revert ExpiredIntent();
        }

        if (_intent.recipient != address(this)) {
            // only support the recipient is this contract
            revert InvalidRecipient();
        }

        if (!tokenInWhitelist[_intent.tokenIn]) {
            revert InvalidTokenIn();
        }

        if (_intent.tokenOut != recipientCurrency) {
            revert InvalidTokenOut(recipientCurrency);
        }

        if (_intent.tokenInAmount == 0 || _intent.tokenOutAmount == 0) {
            revert InvalidAmount();
        }

        _;
    }
}
