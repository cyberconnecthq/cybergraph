// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC1155 } from "solmate/src/tokens/ERC1155.sol";

import { ICyberNFT1155 } from "../interfaces/ICyberNFT1155.sol";

/**
 * @title Cyber NFT Base
 * @author CyberConnect
 * @notice This contract is the base for all NFT contracts.
 */
abstract contract CyberNFT1155 is ERC1155, ICyberNFT1155 {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/
    mapping(uint256 => uint256) internal _totalSupply;
    uint256 internal _totalSupplyAll;

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberNFT1155
    function totalSupply(
        uint256 tokenId
    ) external view virtual override returns (uint256) {
        return _totalSupply[tokenId];
    }

    /// @inheritdoc ICyberNFT1155
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupplyAll;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberNFT1155
    function burn(
        address account,
        uint256 tokenId,
        uint256 amount
    ) public virtual override {
        require(
            msg.sender == account || isApprovedForAll[account][msg.sender],
            "NOT_OWNER_OR_APPROVED"
        );
        require(balanceOf[account][tokenId] >= amount, "INSUFFICIENT_BALANCE");
        _totalSupply[tokenId] -= amount;
        _totalSupplyAll -= amount;

        super._burn(account, tokenId, amount);
    }

    /// @inheritdoc ICyberNFT1155
    function burnBatch(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) public virtual override {
        require(
            msg.sender == account || isApprovedForAll[account][msg.sender],
            "NOT_OWNER_OR_APPROVED"
        );

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            require(
                balanceOf[account][tokenId] >= amount,
                "INSUFFICIENT_BALANCE"
            );

            _totalSupply[tokenId] -= amount;
            _totalSupplyAll -= amount;
        }

        super._batchBurn(account, tokenIds, amounts);
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) internal virtual override {
        _totalSupplyAll += _amount;
        _totalSupply[_tokenId] += _amount;

        super._mint(_to, _tokenId, _amount, _data);
    }

    function _batchMint(
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal virtual override {
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            uint256 tokenId = _tokenIds[i];
            uint256 amount = _amounts[i];

            _totalSupply[tokenId] += amount;
            _totalSupplyAll += amount;
        }

        super._batchMint(_to, _tokenIds, _amounts, _data);
    }
}
