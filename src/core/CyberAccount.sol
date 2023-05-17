// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import { ECDSA } from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { BaseAccount } from "account-abstraction/contracts/core/BaseAccount.sol";

import { IERC1271 } from "../interfaces/IERC1271.sol";
import { ICyberAccount } from "../interfaces/ICyberAccount.sol";
import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { UserOperation } from "account-abstraction/contracts/interfaces/UserOperation.sol";

import { TokenCallbackHandler } from "../callback/TokenCallbackHandler.sol";

contract CyberAccount is
    BaseAccount,
    TokenCallbackHandler,
    UUPSUpgradeable,
    Initializable,
    IERC1271,
    ICyberAccount
{
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    address public owner;
    IEntryPoint private immutable _ENTRYPOINT;
    bytes4 private constant SELECTOR_ERC1271_BYTES32_BYTES = 0x1626ba7e;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        require(
            msg.sender == owner || msg.sender == address(this),
            "CA_NOT_OWNER"
        );
        _;
    }

    modifier onlyEntryPointOrOwner() {
        require(
            msg.sender == address(entryPoint()) || msg.sender == owner,
            "CA_NOT_OWNER_OR_ENTRYPOINT"
        );
        _;
    }

    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _ENTRYPOINT;
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IEntryPoint anEntryPoint) {
        _ENTRYPOINT = anEntryPoint;
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberAccount
    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external override onlyEntryPointOrOwner {
        _call(dest, value, func);
    }

    /// @inheritdoc ICyberAccount
    function executeBatch(
        address[] calldata dest,
        bytes[] calldata func
    ) external override onlyEntryPointOrOwner {
        require(dest.length == func.length, "CA_WRONG_ARRAY_LENGTH");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    /// @inheritdoc IERC1271
    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view override returns (bytes4) {
        if (owner != _hash.recover(_signature)) {
            return SELECTOR_ERC1271_BYTES32_BYTES;
        } else {
            return 0xffffffff;
        }
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    function initialize(address anOwner) public virtual initializer {
        owner = anOwner;
        emit CyberAccountInitialized(_ENTRYPOINT, owner);
    }

    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    function addDeposit() public payable {
        entryPoint().depositTo{ value: msg.value }(address(this));
    }

    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) public onlyOwner {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (owner != hash.recover(userOp.signature))
            return SIG_VALIDATION_FAILED;
        return 0;
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{ value: value }(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override onlyOwner {
        (newImplementation);
    }
}
