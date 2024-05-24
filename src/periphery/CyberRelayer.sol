pragma solidity ^0.8.0;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { AccessControlEnumerable } from "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";

contract CyberRelayer is AccessControlEnumerable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            EVENT
    //////////////////////////////////////////////////////////////*/

    event Relayed(bytes32 relayId);

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    mapping(bytes32 => bool) public relayed;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    /*//////////////////////////////////////////////////////////////
                            ONLY RELAYER 
    //////////////////////////////////////////////////////////////*/

    function relay(
        bytes32 relayId,
        address to,
        uint256 value,
        bytes calldata data
    ) external payable onlyRole(RELAYER_ROLE) {
        require(msg.value == value, "INVALID_VALUE");
        require(!relayed[relayId], "ALREADY_RELAYED");
        relayed[relayId] = true;
        bool success;
        bytes memory ret;

        (success, ret) = _call(to, value, data);
        if (!success) {
            assembly {
                revert(add(ret, 32), mload(ret))
            }
        }

        emit Relayed(relayId);
    }

    /*//////////////////////////////////////////////////////////////
                            ONLY ADMIN 
    //////////////////////////////////////////////////////////////*/

    function withdraw(
        address to,
        address token,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (token == address(0)) {
            (bool success, ) = to.call{ value: amount }("");
            require(success, "WITHDRAW_FAILED");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE 
    //////////////////////////////////////////////////////////////*/

    function _call(
        address to,
        uint256 value,
        bytes memory data
    ) private returns (bool success, bytes memory returnData) {
        assembly {
            success := call(
                gas(),
                to,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let len := returndatasize()
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, add(len, 0x20)))
            mstore(ptr, len)
            returndatacopy(add(ptr, 0x20), 0, len)
            returnData := ptr
        }
    }
}
