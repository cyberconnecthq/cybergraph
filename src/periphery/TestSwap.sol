// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract TestSwap {
    using SafeERC20 for IERC20;

    event Swap(address indexed from, address indexed to, uint256 amount);

    constructor() {}

    function swap(address from, address to, uint256 amount) external {
        IERC20(from).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(to).safeTransfer(msg.sender, amount);
        emit Swap(from, to, amount);
    }
}
