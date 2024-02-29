// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { Pausable } from "openzeppelin-contracts/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

/**
 * @title LaunchTokenPool
 * @author CyberConnect
 */
contract LaunchTokenPool is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            EVENT
    //////////////////////////////////////////////////////////////*/

    event Deposit(address to, uint256 amount);
    event WithdrawCyber(address to, uint256 amount);
    event WithdrawERC20(address currency, address to, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public deposits;
    uint256 public totalDeposits;
    IERC20 public cyber;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, address _cyber) {
        _transferOwnership(_owner);
        cyber = IERC20(_cyber);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function deposit(
        address to,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        require(amount > 0, "ZERO_DEPOSIT");
        cyber.safeTransferFrom(msg.sender, address(this), amount);
        deposits[to] += amount;
        totalDeposits += amount;
        emit Deposit(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            ONLY OWNER 
    //////////////////////////////////////////////////////////////*/

    function withdraw(address to, uint256 amount) external onlyOwner {
        cyber.safeTransfer(to, amount);
        emit WithdrawCyber(to, amount);
    }

    function withdrawERC20(
        address currency,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(currency).safeTransfer(to, amount);
        emit WithdrawERC20(currency, to, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
