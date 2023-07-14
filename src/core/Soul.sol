// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { SBTERC721 } from "../dependencies/solmate/SBTERC721.sol";

import { ISoul } from "../interfaces/ISoul.sol";

import { MetadataResolver } from "../base/MetadataResolver.sol";
import { LibString } from "../libraries/LibString.sol";

/**
 * @title Soul
 * @author CyberConnect
 * @notice A 721 NFT contract that indicates if an address is a CyberAccount.
 */
contract Soul is Ownable, SBTERC721, MetadataResolver, ISoul {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) internal _orgs;
    string internal _tokenURI;
    mapping(address => bool) internal _minters;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks the sender is a minter.
     */
    modifier onlyMinter() {
        require(_minters[msg.sender], "ONLY_MINTER");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol
    ) SBTERC721(_name, _symbol) {
        _minters[_owner] = true;
        _transferOwnership(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISoul
    function createSoul(
        address to,
        bool isOrg
    ) external override onlyMinter returns (uint256) {
        if (isOrg) {
            _orgs[to] = true;
        }
        uint256 tokenId = super._safeMint(to);
        emit CreateSoul(to, isOrg, tokenId);

        return tokenId;
    }

    /// @inheritdoc ISoul
    function setOrg(address account, bool isOrg) external override onlyMinter {
        _orgs[account] = isOrg;

        emit SetOrg(account, isOrg);
    }

    /// @inheritdoc ISoul
    function setMinter(
        address account,
        bool _isMinter
    ) external override onlyOwner {
        _minters[account] = _isMinter;

        emit SetMinter(account, _isMinter);
    }

    /// @inheritdoc ISoul
    function isOrgAccount(
        address account
    ) external view override returns (bool) {
        require(balanceOf(account) > 0, "NOT_SOUL_OWNER");
        return _orgs[account];
    }

    /// @inheritdoc ISoul
    function isMinter(address account) external view override returns (bool) {
        return _minters[account];
    }

    /// @inheritdoc ISoul
    function setTokenURI(string calldata uri) external override onlyOwner {
        _tokenURI = uri;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /// ERC721
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_balanceOf[address(uint160(tokenId))] != 0, "NOT_MINTED");
        return string(abi.encodePacked(_tokenURI, LibString.toString(tokenId)));
    }

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/
    function _isMetadataAuthorised(
        uint256 tokenId
    ) internal view override returns (bool) {
        address from = address(uint160(tokenId));

        return
            msg.sender == from ||
            isApprovedForAll[from][msg.sender] ||
            msg.sender == getApproved[tokenId];
    }

    function _isGatedMetadataAuthorised(
        uint256
    ) internal view override returns (bool) {
        return _minters[msg.sender];
    }
}
