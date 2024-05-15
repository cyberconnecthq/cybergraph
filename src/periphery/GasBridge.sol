// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { Pausable } from "openzeppelin-contracts/contracts/security/Pausable.sol";

contract GasBridge is Ownable, Pausable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            EVENT
    //////////////////////////////////////////////////////////////*/

    event Bridge(
        uint256 logId,
        address from,
        address to,
        uint256 amount,
        uint256 chains
    );

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 private _logId;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function bridge(address to, uint256 chains) external payable whenNotPaused {
        emit Bridge(_logId++, msg.sender, to, msg.value, chains);
    }

    /*//////////////////////////////////////////////////////////////
                            ONLY OWNER 
    //////////////////////////////////////////////////////////////*/

    function withdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = owner().call{ value: amount }("");
            require(success, "WITHDRAW_FAILED");
        } else {
            IERC20(token).safeTransfer(owner(), amount);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
