// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { Pausable } from "openzeppelin-contracts/contracts/security/Pausable.sol";
import { ERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract CyberNFT is
    ERC1155Supply,
    AccessControl,
    Pausable,
    UUPSUpgradeable,
    Initializable
{
    using Strings for uint256;
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR & INITIALIZER
    //////////////////////////////////////////////////////////////*/
    constructor() ERC1155("") {}

    function initialize(address _owner) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(MANAGER_ROLE, _owner);
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function setURI(string calldata newuri) external onlyRole(MANAGER_ROLE) {
        _setURI(newuri);
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external whenNotPaused onlyRole(MANAGER_ROLE) {
        require(tokenId != 0, "INVALID_TOKEN_ID");
        require(amount != 0, "INVALID_AMOUNT");

        _mint(to, tokenId, amount, "");
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/
    function uri(uint256 tokenId) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    ERC1155.uri(tokenId),
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function name() public pure returns (string memory) {
        return "Cyber NFT";
    }

    function symbol() public pure returns (string memory) {
        return "CyberNFT";
    }

    /*//////////////////////////////////////////////////////////////
                            ONLY OWNER 
    //////////////////////////////////////////////////////////////*/
    function _authorizeUpgrade(
        address
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
