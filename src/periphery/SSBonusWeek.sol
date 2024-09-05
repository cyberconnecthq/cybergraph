// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";
import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { Pausable } from "openzeppelin-contracts/contracts/security/Pausable.sol";
import { ERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract SSBonusWeek is ERC1155Supply, AccessControl, Pausable {
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
    /// @notice Invalid amount
    error InvalidAmount();

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    uint96 internal constant MINT_FEE = 0.00003 ether;
    uint96 internal constant CREATOR_SHARE = 0.000024 ether; // 80% of mint fee
    uint96 internal constant CYBER_SHARE = 0.000006 ether; // 20% of mint fee

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address private immutable cyberTreasury;

    struct TokenInfo {
        string tokenURI;
        address creator;
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
        address indexed creator,
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
    constructor(address owner_, address cyberTreasury_) ERC1155("") {
        if (owner_ == address(0)) {
            revert InvalidAddressZero();
        }
        cyberTreasury = cyberTreasury_;

        _grantRole(MANAGER_ROLE, owner_);
        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
    }

    function name() public pure returns (string memory) {
        return "Social Summer Bonus Week";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public pure returns (string memory) {
        return "SocialSummerBonusWeek-NFT";
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL UPDATE
    //////////////////////////////////////////////////////////////*/
    function setTokenInfo(
        uint256 tokenId,
        string calldata _tokenURI,
        address _creator,
        uint256 _mintStartTimestamp
    ) external onlyRole(MANAGER_ROLE) {
        tokenInfo[tokenId] = TokenInfo(
            _tokenURI,
            _creator,
            _mintStartTimestamp
        );
        emit TokenInfoUpdated(
            tokenId,
            _tokenURI,
            _creator,
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
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (to == address(0)) {
            revert InvalidAddressZero();
        }
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
        payable(tokenInfo[tokenId].creator).sendValue(CREATOR_SHARE * amount);
        payable(cyberTreasury).sendValue(CYBER_SHARE * amount);
    }
}
