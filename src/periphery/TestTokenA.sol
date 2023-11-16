// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TestTokenA is ERC20 {
    constructor() ERC20("Test Token A", "TTA") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
