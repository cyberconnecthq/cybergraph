// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { Pausable } from "openzeppelin-contracts/contracts/security/Pausable.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

import { RelayParams, ICyberRelayGateHook } from "../interfaces/ICyberRelayGateHook.sol";

contract CyberRelayGate is Ownable, Pausable, Initializable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STRUCT
    //////////////////////////////////////////////////////////////*/

    struct RelayDestination {
        bool enabled;
        ICyberRelayGateHook hook;
    }

    /*//////////////////////////////////////////////////////////////
                            EVENT
    //////////////////////////////////////////////////////////////*/

    event Relay(
        bytes32 requestId,
        address from,
        address destination,
        uint256 value,
        bytes callData
    );

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(bytes32 => bool)) public requestIdUsed;
    mapping(address => RelayDestination) public relayDestinations;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR & INITIALIZER
    //////////////////////////////////////////////////////////////*/

    constructor() {}

    function initialize(address _owner) external initializer {
        _transferOwnership(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function relayToCyber(
        bytes32 requestId,
        address destination,
        bytes calldata data
    ) external payable whenNotPaused {
        require(destination != address(0), "INVALID_ADDRESS_ZERO");
        require(requestId != bytes32(0), "INVALID_REQUEST_ID");

        RelayDestination memory relayDestination = relayDestinations[
            destination
        ];
        require(relayDestination.enabled, "DESTINATION_DISABLED");
        require(address(relayDestination.hook) != address(0), "HOOK_NOT_SET");
        require(!requestIdUsed[destination][requestId], "REQUEST_ID_USED");
        requestIdUsed[destination][requestId] = true;

        uint256 valueBefore = address(this).balance;

        RelayParams memory relayParams = relayDestination.hook.processRelay{
            value: msg.value
        }(msg.sender, destination, data);

        require(address(this).balance == valueBefore, "BALANCE_CHANGED");

        emit Relay(
            requestId,
            msg.sender,
            relayParams.to,
            relayParams.value,
            relayParams.callData
        );
    }

    /*//////////////////////////////////////////////////////////////
                            ONLY OWNER 
    //////////////////////////////////////////////////////////////*/

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = owner().call{ value: address(this).balance }("");
            require(success, "WITHDRAW_FAILED");
        } else {
            IERC20(token).safeTransfer(
                owner(),
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setDestination(
        address destination,
        bool enabled,
        address hook
    ) external onlyOwner {
        relayDestinations[destination] = RelayDestination(
            enabled,
            ICyberRelayGateHook(hook)
        );
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
