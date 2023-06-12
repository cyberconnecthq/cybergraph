// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockERC20", "MERC") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
