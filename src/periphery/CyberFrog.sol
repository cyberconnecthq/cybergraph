pragma solidity ^0.8.0;

import { ERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Burnable } from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import { ERC1155Pausable } from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import { AccessControlEnumerable } from "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import { Context } from "openzeppelin-contracts/contracts/utils/Context.sol";

contract CyberFrog is
    Context,
    AccessControlEnumerable,
    ERC1155Burnable,
    ERC1155Pausable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public payable virtual {
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        _mintBatch(to, ids, amounts, data);
    }

    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC1155PresetMinterPauser: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC1155PresetMinterPauser: must have pauser role to unpause"
        );
        _unpause();
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdraw(address to, uint256 amount) external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC1155PresetMinterPauser: must have pauser role to withdraw"
        );
        payable(to).transfer(amount);
    }
}
