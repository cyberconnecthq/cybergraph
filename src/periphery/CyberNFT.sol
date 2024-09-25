// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { Pausable } from "openzeppelin-contracts/contracts/security/Pausable.sol";
import { ERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract CyberNFT is ERC1155Supply, AccessControl, Pausable {
    using Strings for uint256;
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address owner_) ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
        _grantRole(MANAGER_ROLE, owner_);
    }

    function name() public pure returns (string memory) {
        return "Cyber NFT";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public pure returns (string memory) {
        return "CyberNFT";
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
}
