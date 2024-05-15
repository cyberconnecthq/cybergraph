// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { Pausable } from "openzeppelin-contracts/contracts/security/Pausable.sol";

contract CyberNewEraGate is Ownable, Pausable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            EVENT
    //////////////////////////////////////////////////////////////*/

    event Mint(uint256 logId, address to);

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 private _logId;
    uint256 public immutable _mintFee;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, uint256 mintFee) {
        _transferOwnership(_owner);
        _mintFee = mintFee;
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function mint() external payable whenNotPaused {
        require(msg.value == _mintFee, "WRONG_MINT_FEE");
        emit Mint(_logId++, msg.sender);
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
