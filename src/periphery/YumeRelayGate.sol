// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { Pausable } from "openzeppelin-contracts/contracts/security/Pausable.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

import { RelayParams, IYumeRelayGateHook } from "../interfaces/IYumeRelayGateHook.sol";

contract YumeRelayGate is Ownable, Pausable, Initializable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STRUCT
    //////////////////////////////////////////////////////////////*/

    struct RelayDestination {
        bool enabled;
        IYumeRelayGateHook hook;
    }

    struct BatchSetDestinationParams {
        uint256 destinationChainId;
        address destination;
        bool enabled;
        address hook;
    }

    /*//////////////////////////////////////////////////////////////
                            EVENT
    //////////////////////////////////////////////////////////////*/

    event Relay(
        bytes32 requestId,
        address from,
        uint256 destinationChainId,
        address destination,
        uint256 value,
        bytes callData
    );

    event DestinationUpdated(
        uint256 chainId,
        address destination,
        bool enabled,
        address hook
    );

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => mapping(address => mapping(bytes32 => bool))) public requestIdUsed;
    mapping(uint256 => mapping(address => RelayDestination)) public relayDestinations;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR & INITIALIZER
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function relay(
        bytes32 requestId,
        uint256 destinationChainId,
        address destination,
        bytes calldata data
    ) external payable whenNotPaused {
        require(destination != address(0), "INVALID_ADDRESS_ZERO");
        require(requestId != bytes32(0), "INVALID_REQUEST_ID");

        RelayDestination memory relayDestination = relayDestinations[destinationChainId][destination];
        require(relayDestination.enabled, "DESTINATION_DISABLED");
        require(address(relayDestination.hook) != address(0), "HOOK_NOT_SET");
        require(!requestIdUsed[destinationChainId][destination][requestId], "REQUEST_ID_USED");
        requestIdUsed[destinationChainId][destination][requestId] = true;

        uint256 valueBefore = address(this).balance;

        RelayParams memory relayParams = relayDestination.hook.processRelay{
            value: msg.value
        }(msg.sender, destinationChainId, destination, data);

        require(
            address(this).balance == valueBefore - msg.value,
            "BALANCE_CHANGED"
        );

        emit Relay(
            requestId,
            msg.sender,
            destinationChainId,
            relayParams.to,
            relayParams.value,
            relayParams.callData
        );
    }

    function getRelayDestination(uint256 destinationChainId, address destination) external view returns (RelayDestination memory) {
        return relayDestinations[destinationChainId][destination];
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
        uint256 destinationChainId,
        address destination,
        bool enabled,
        address hook
    ) external onlyOwner {
        _setDestination(destinationChainId, destination, enabled, hook);
    }

    function batchSetDestination(BatchSetDestinationParams[] calldata params) external onlyOwner {
        for (uint256 i = 0; i < params.length; i++) {
            _setDestination(
                params[i].destinationChainId,
                params[i].destination,
                params[i].enabled,
                params[i].hook
            );
        }
    }

    function _setDestination(
        uint256 destinationChainId,
        address destination,
        bool enabled,
        address hook
    ) internal {
        require(destination != address(0), "INVALID_DESTINATION");
        require(hook != address(0), "INVALID_HOOK");
        relayDestinations[destinationChainId][destination] = RelayDestination(
            enabled,
            IYumeRelayGateHook(hook)
        );
        emit DestinationUpdated(destinationChainId, destination, enabled, hook);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
