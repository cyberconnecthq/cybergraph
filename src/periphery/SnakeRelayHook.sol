// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "../interfaces/ICyberRelayGateHook.sol";

/**
 * @title SnakeRelayHook
 * @author Cyber
 */
contract SnakeRelayHook is ICyberRelayGateHook {
    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    address public immutable recipient;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _recipient) {
        recipient = _recipient;
    }

    /*//////////////////////////////////////////////////////////////
                    ICyberRelayGateHook OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function processRelay(
        address msgSender,
        address destination,
        bytes calldata
    ) external payable override returns (RelayParams memory) {
        (bool chargeSuccess, ) = recipient.call{ value: msg.value }("");
        require(chargeSuccess, "CHARGE_FAILED");

        RelayParams memory relayParams;
        relayParams.to = destination;
        relayParams.value = msg.value;
        relayParams.callData = abi.encodePacked(msgSender);
        return relayParams;
    }
}
