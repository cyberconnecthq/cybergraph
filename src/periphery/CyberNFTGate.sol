// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { Pausable } from "openzeppelin-contracts/contracts/security/Pausable.sol";

contract CyberNFTGate is Ownable, Pausable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STRUCT
    //////////////////////////////////////////////////////////////*/

    struct NFTConfig {
        bool isWhitelist;
        uint256 mintFee;
    }

    /*//////////////////////////////////////////////////////////////
                            EVENT
    //////////////////////////////////////////////////////////////*/

    event Mint(
        bytes32 requestId,
        address from,
        address nft,
        address to,
        uint256 tokenId,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(bytes32 => bool) public requestIdUsed;
    mapping(address => NFTConfig) public nftConfigs;
    uint256 public fixedFee;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR & INITIALIZER
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        _transferOwnership(_owner);
        fixedFee = 0.000003 ether;
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function mint(
        bytes32 requestId,
        address nft,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external payable whenNotPaused {
        NFTConfig memory nftConfig = nftConfigs[nft];
        require(nftConfig.isWhitelist, "NFT_NOT_WHITELISTED");
        require(msg.value == requiredFee(nft, amount), "WRONG_MINT_FEE");
        require(!requestIdUsed[requestId], "REQUEST_ID_USED");
        requestIdUsed[requestId] = true;

        emit Mint(requestId, msg.sender, nft, to, tokenId, amount);
    }

    function requiredFee(
        address nft,
        uint256 amount
    ) public view returns (uint256) {
        NFTConfig memory nftConfig = nftConfigs[nft];
        return amount * nftConfig.mintFee + fixedFee;
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

    function setNFTConfig(
        address nft,
        bool isWhitelist,
        uint256 mintFee
    ) external onlyOwner {
        nftConfigs[nft] = NFTConfig(isWhitelist, mintFee);
    }

    function setFixedFee(uint256 fee) external onlyOwner {
        fixedFee = fee;
    }
}
