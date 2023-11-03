// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

/**
 * @title CyberVault
 * @author CyberConnect
 * @notice This contract is used to create deposit and distribute tokens.
 */
contract CyberVault is
    Initializable,
    AccessControl,
    UUPSUpgradeable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            EVENT
    //////////////////////////////////////////////////////////////*/
    event Deposit(address to, uint256 amount);
    event Withdraw(address to, uint256 amount);
    event Consume(
        address consumer,
        address receiver,
        uint256 amount,
        uint256 fee
    );

    event DepositERC20(address to, address currency, uint256 amount);
    event WithdrawERC20(address to, address currency, uint256 amount);
    event ConsumeERC20(
        address consumer,
        address receiver,
        address currency,
        uint256 amount,
        uint256 fee
    );

    event ReceipientChanged(address receipient);

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    address public receipient;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public balancesByCurrency;

    bytes32 internal constant _OPERATOR_ROLE =
        keccak256(bytes("OPERATOR_ROLE"));

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR & INITIALIZER
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        address _receipient
    ) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(_OPERATOR_ROLE, _owner);
        receipient = _receipient;
        emit ReceipientChanged(_receipient);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function deposit(address to) external payable nonReentrant {
        balances[to] += msg.value;
        emit Deposit(to, msg.value);
    }

    function depositERC20(
        address from,
        address to,
        address currency,
        uint256 amount
    ) external nonReentrant {
        IERC20(currency).safeTransferFrom(from, address(this), amount);
        balancesByCurrency[to][currency] += amount;
        emit DepositERC20(to, currency, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            ONLY OPERATOR 
    //////////////////////////////////////////////////////////////*/

    function withdraw(
        address to,
        uint256 amount
    ) external onlyRole(_OPERATOR_ROLE) {
        require(balances[to] >= amount, "INSUFFICIENT_BALANCE");
        (bool success, ) = to.call{ value: amount }("");
        require(success, "WITHDRAW_FAILED");
        emit Withdraw(to, amount);
    }

    function withdrawERC20(
        address to,
        address currency,
        uint256 amount
    ) external onlyRole(_OPERATOR_ROLE) {
        require(
            balancesByCurrency[to][currency] >= amount,
            "INSUFFICIENT_BALANCE"
        );
        IERC20(currency).safeTransfer(to, amount);
        emit WithdrawERC20(to, currency, amount);
    }

    function consume(
        address consumer,
        address receiver,
        uint256 amount,
        uint256 fee
    ) external onlyRole(_OPERATOR_ROLE) {
        uint256 total = amount + fee;
        require(balances[consumer] >= total, "INSUFFICIENT_BALANCE");
        balances[consumer] -= total;

        (bool success, ) = receiver.call{ value: amount }("");
        require(success, "CONSUME_FAILED");

        (success, ) = receipient.call{ value: fee }("");
        require(success, "CHARGE_FAILED");

        emit Consume(consumer, receiver, amount, fee);
    }

    function consumeERC20(
        address consumer,
        address receiver,
        address currency,
        uint256 amount,
        uint256 fee
    ) external onlyRole(_OPERATOR_ROLE) {
        uint256 total = amount + fee;
        require(
            balancesByCurrency[consumer][currency] >= total,
            "INSUFFICIENT_BALANCE"
        );
        balancesByCurrency[consumer][currency] -= total;

        IERC20(currency).safeTransfer(receiver, amount);
        IERC20(currency).safeTransfer(receipient, fee);

        emit ConsumeERC20(consumer, receiver, currency, amount, fee);
    }

    /*//////////////////////////////////////////////////////////////
                            ONLY OWNER
    //////////////////////////////////////////////////////////////*/

    function setReceipient(
        address _receipient
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        receipient = _receipient;
        emit ReceipientChanged(_receipient);
    }

    function _authorizeUpgrade(address) internal view override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    }
}
