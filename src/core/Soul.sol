// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Owned } from "../dependencies/solmate/Owned.sol";

import { ISoul } from "../interfaces/ISoul.sol";

import { CyberNFT721 } from "../base/CyberNFT721.sol";

contract Soul is Owned, CyberNFT721, ISoul {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) internal _orgs;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address owner,
        string calldata name,
        string calldata symbol
    ) external initializer {
        Owned.__Owned_Init(owner);
        super._initialize(name, symbol);
    }

    /// @inheritdoc ISoul
    function createSoul(
        address to,
        bool isOrg
    ) external override onlyOwner returns (uint256) {
        if (isOrg) {
            _orgs[to] = true;
        }
        uint256 tokenId = super._mint(to);
        emit CreateSoul(to, isOrg, tokenId);

        return tokenId;
    }

    /// @inheritdoc ISoul
    function setOrg(address account, bool isOrg) external override onlyOwner {
        require(balanceOf(account) > 0, "NOT_SOUL_OWNER");
        _orgs[account] = isOrg;

        emit SetOrg(account, isOrg);
    }

    /// @inheritdoc ISoul
    function isOrgAccount(
        address account
    ) external view override returns (bool) {
        require(balanceOf(account) > 0, "NOT_SOUL_OWNER");
        return _orgs[account];
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Disallows the transfer of the soul.
     */
    function transferFrom(address, address, uint256) public pure override {
        revert("TRANSFER_NOT_ALLOWED");
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Generates the metadata json object.
     *
     * @param tokenId The profile NFT token ID.
     * @return string The metadata json object.
     * @dev It requires the tokenId to be already minted.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        // TODO: tokenURI
        return "";
    }
}
