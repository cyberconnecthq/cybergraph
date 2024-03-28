// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IBridge } from "../../src/interfaces/IBridge.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockBridge is IBridge {
    using SafeERC20 for IERC20;

    address public pool;

    constructor(address _pool) {
        pool = _pool;
    }

    function bridge(
        address,
        address recipient,
        address asset,
        uint256 amount
    ) external {
        IERC20(asset).safeTransferFrom(pool, recipient, amount);
    }
}
