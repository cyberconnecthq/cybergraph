// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

import { CyberNFT1155 } from "../base/CyberNFT1155.sol";

contract SpecialReward is CyberNFT1155, Ownable {
    uint256 internal constant _TOKEN_ID = 0;
    string internal _tokenURI;

    constructor(address owner, string memory tokenURI) {
        _tokenURI = tokenURI;
        transferOwnership(owner);
    }

    function mintBatch(
        address[] calldata _tos,
        uint256[] calldata _amounts
    ) external onlyOwner {
        for (uint256 i = 0; i < _tos.length; i++) {
            _mint(_tos[i], _TOKEN_ID, _amounts[i], "");
        }
    }

    function uri(uint256) public view override returns (string memory) {
        return _tokenURI;
    }
}
