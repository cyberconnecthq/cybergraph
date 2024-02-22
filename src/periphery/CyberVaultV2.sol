// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

/**
 * @title CyberVaultV2
 * @author CyberConnect
 * @notice This contract is used to create deposit and distribute tokens.
 */
contract CyberVaultV2 is
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

    uint256 public balance;
    mapping(address => uint256) public erc20balances;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR & INITIALIZER
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function deposit(address to) external payable nonReentrant {
        balance += msg.value;
        emit Deposit(to, msg.value);
    }

    function depositERC20(
        address from,
        address to,
        address currency,
        uint256 amount
    ) external nonReentrant {
        IERC20(currency).safeTransferFrom(from, address(this), amount);
        erc20balances[currency] += amount;
        emit DepositERC20(to, currency, amount);
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

    /*//////////////////////////////////////////////////////////////
                            ONLY OWNER
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address) internal view override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    }
}
