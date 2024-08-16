// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";
import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { Pausable } from "openzeppelin-contracts/contracts/security/Pausable.sol";
import { ERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract CyberProjectNFTV2 is ERC1155Supply, AccessControl, Pausable {
    using Address for address payable;

    /*//////////////////////////////////////////////////////////////
                             ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Address provided is invalid
    error InvalidAddressZero();
    /// @notice Token has not been created
    error NotCreatedToken();
    /// @notice Token minting is not started
    error MintNotStarted();
    /// @notice Incorrect payment
    error IncorrectPayment();

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    uint96 internal constant MINT_FEE = 0.00003 ether;
    uint96 internal constant PROJECT_SHARE = 0.0000105 ether; // 35% of mint fee
    uint96 internal constant PHI_SHARE = 0.000006 ether; // 20% of mint fee
    uint96 internal constant CYBER_SHARE = 0.0000099 ether; // 33% of mint fee
    uint96 internal constant ARTIST_SHARE = 0.0000036 ether; // 12% of mint fee

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address private immutable cyberTreasury;
    address private immutable phiTreasury;

    struct TokenInfo {
        string tokenURI;
        address artist;
        address project;
        uint256 mintStartTimestamp;
    }

    /// @notice Mapping of token ID to token info
    mapping(uint256 => TokenInfo) public tokenInfo;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a user mints
    event Mint(address indexed to, uint256 indexed tokenId, uint256 amount);

    /// @notice Emitted when a token is created or updated
    event TokenInfoUpdated(
        uint256 indexed tokenId,
        string tokenURI,
        address indexed artist,
        address indexed project,
        uint256 mintStartTimestamp
    );

    /// @notice Emitted when the mint start time of a token is updated
    event TokenMintStartTimestampUpdated(
        uint256 indexed tokenId,
        uint256 mintStartTimestamp
    );

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address cyberTreasury_,
        address phiTreasury_,
        address owner_
    ) ERC1155("") {
        if (cyberTreasury_ == address(0) || phiTreasury_ == address(0)) {
            revert InvalidAddressZero();
        }
        cyberTreasury = cyberTreasury_;
        phiTreasury = phiTreasury_;

        _grantRole(MANAGER_ROLE, cyberTreasury_);
        _grantRole(MANAGER_ROLE, phiTreasury_);
        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
    }

    function name() public pure returns (string memory) {
        return "CyberProject";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public pure returns (string memory) {
        return "CyberProject-NFT";
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL UPDATE
    //////////////////////////////////////////////////////////////*/
    function setTokenInfo(
        uint256 tokenId,
        string calldata _tokenURI,
        address _artist,
        address _project,
        uint256 _mintStartTimestamp
    ) external onlyRole(MANAGER_ROLE) {
        tokenInfo[tokenId] = TokenInfo(
            _tokenURI,
            _artist,
            _project,
            _mintStartTimestamp
        );
        emit TokenInfoUpdated(
            tokenId,
            _tokenURI,
            _artist,
            _project,
            _mintStartTimestamp
        );
    }

    function setTokenMintStartTimestamp(
        uint256 tokenId,
        uint256 _mintStartTimestamp
    ) external onlyRole(MANAGER_ROLE) {
        tokenInfo[tokenId].mintStartTimestamp = _mintStartTimestamp;
        emit TokenMintStartTimestampUpdated(tokenId, _mintStartTimestamp);
    }

    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function claim(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external payable whenNotPaused {
        if (bytes(tokenInfo[tokenId].tokenURI).length == 0) {
            revert NotCreatedToken();
        }
        if (tokenInfo[tokenId].mintStartTimestamp > block.timestamp) {
            revert MintNotStarted();
        }
        if (msg.value != MINT_FEE * amount) {
            revert IncorrectPayment();
        }

        _distributeFunds(tokenId, amount);

        emit Mint(to, tokenId, amount);
        _mint(to, tokenId, amount, "");
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/
    // Returns the URI for a token ID
    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokenInfo[tokenId].tokenURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/
    function _distributeFunds(uint256 tokenId, uint256 amount) internal {
        payable(tokenInfo[tokenId].project).sendValue(PROJECT_SHARE * amount);
        payable(phiTreasury).sendValue(PHI_SHARE * amount);
        payable(cyberTreasury).sendValue(CYBER_SHARE * amount);
        payable(tokenInfo[tokenId].artist).sendValue(ARTIST_SHARE * amount);
    }
}
