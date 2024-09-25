// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ICyberRelayGateHook.sol";
import "../interfaces/ICyberID.sol";
import "../interfaces/AggregatorV3Interface.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

import { EIP712 } from "../base/EIP712.sol";

/**
 * @title CyberIDPermissionedRelayHook
 * @author Cyber
 */
contract CyberIDPermissionedRelayHook is ICyberRelayGateHook, EIP712, Ownable {
    using SafeERC20 for IERC20;
    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable signer;
    AggregatorV3Interface public immutable usdOracle;
    address public recipient;

    uint256 public price3Letter;
    uint256 public price4Letter;
    uint256 public price5To9Letter;
    uint256 public price10AndMoreLetter;

    mapping(address => uint256) public nonces;

    bytes32 public constant _REGISTER_TYPEHASH =
        keccak256(
            "register(string cid,address to,uint256 discount,uint256 nonce,uint256 deadline)"
        );

    uint256 internal constant BASE = 1000;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event StableFeeChanged(
        address indexed recipient,
        uint256 price3Letter,
        uint256 price4Letter,
        uint256 price5To9Letter,
        uint256 price10AndMoreLetter
    );

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _owner,
        address _signer,
        address _recipient,
        address _oracleAddress
    ) {
        _transferOwnership(_owner);
        signer = _signer;
        recipient = _recipient;
        usdOracle = AggregatorV3Interface(_oracleAddress);
    }

    /*//////////////////////////////////////////////////////////////
                    ICyberRelayGateHook OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function processRelay(
        address msgSender,
        address destination,
        bytes calldata data
    ) external payable override returns (RelayParams memory) {
        DataTypes.EIP712Signature memory sig;
        string memory cid;
        address to;
        uint256 discount;
        (cid, to, discount, sig.v, sig.r, sig.s, sig.deadline) = abi.decode(
            data,
            (string, address, uint256, uint8, bytes32, bytes32, uint256)
        );

        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _REGISTER_TYPEHASH,
                        keccak256(bytes(cid)),
                        to,
                        discount,
                        nonces[to]++,
                        sig.deadline
                    )
                )
            ),
            signer,
            sig.v,
            sig.r,
            sig.s,
            sig.deadline
        );

        uint256 cost = (getPriceWei(cid) * discount) / BASE;

        _chargeAndRefundOverPayment(cost, msgSender);

        RelayParams memory relayParams;
        relayParams.to = destination;
        relayParams.value = 0;
        BatchRegisterCyberIdParams[1] memory params = [
            BatchRegisterCyberIdParams(cid, to, false)
        ];
        relayParams.callData = abi.encodeWithSelector(
            ICyberID.privilegedRegister.selector,
            params
        );
        return relayParams;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    function getPriceWei(string memory cid) public view returns (uint256) {
        return _attoUSDToWei(_getUSDPrice(cid));
    }

    /*//////////////////////////////////////////////////////////////
                    EIP712 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function _domainSeparatorName()
        internal
        pure
        override
        returns (string memory)
    {
        return "CyberIDPermissionedRelayHook";
    }

    /*//////////////////////////////////////////////////////////////
                    ONLY OWNER
    //////////////////////////////////////////////////////////////*/

    function rescueToken(address token) external onlyOwner {
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

    function config(
        address _recipient,
        uint256[4] memory prices
    ) external onlyOwner {
        require(_recipient != address(0), "INVALID_RECIPIENT");
        price3Letter = prices[0];
        price4Letter = prices[1];
        price5To9Letter = prices[2];
        price10AndMoreLetter = prices[3];

        emit StableFeeChanged(
            _recipient,
            prices[0],
            prices[1],
            prices[2],
            prices[3]
        );
    }

    /*//////////////////////////////////////////////////////////////
                    PRIVATE
    //////////////////////////////////////////////////////////////*/

    function _chargeAndRefundOverPayment(
        uint256 cost,
        address refundTo
    ) internal {
        require(msg.value >= cost, "INSUFFICIENT_FUNDS");
        /**
         * Already checked msg.value >= cost
         */
        uint256 overpayment;
        unchecked {
            overpayment = msg.value - cost;
        }

        if (overpayment > 0) {
            (bool refundSuccess, ) = refundTo.call{ value: overpayment }("");
            require(refundSuccess, "REFUND_FAILED");
        }
        if (cost > 0) {
            (bool chargeSuccess, ) = recipient.call{ value: cost }("");
            require(chargeSuccess, "CHARGE_FAILED");
        }
    }

    function _getUSDPrice(string memory cid) internal view returns (uint256) {
        // LowerCaseCyberIdMiddleware ensures that each cid character only occupies 1 byte
        uint256 len = bytes(cid).length;
        uint256 usdPrice;

        if (len >= 10) {
            usdPrice = price10AndMoreLetter;
        } else if (len >= 5) {
            usdPrice = price5To9Letter;
        } else if (len == 4) {
            usdPrice = price4Letter;
        } else if (len == 3) {
            usdPrice = price3Letter;
        } else {
            revert("INVALID_LENGTH");
        }
        return usdPrice;
    }

    function _getPrice() internal view returns (int256) {
        // prettier-ignore
        (
            uint80 roundID,
            int price,
            /* uint startedAt */,
            uint updatedAt,
            /*uint80 answeredInRound*/
        ) = usdOracle.latestRoundData();
        require(roundID != 0, "INVALID_ORACLE_ROUND_ID");
        require(price > 0, "INVALID_ORACLE_PRICE");
        require(updatedAt > block.timestamp - 12 hours, "STALE_ORACLE_PRICE");
        return price;
    }

    function _attoUSDToWei(uint256 amount) internal view returns (uint256) {
        uint256 ethPrice = uint256(_getPrice());
        return (amount * 1e8) / ethPrice;
    }
}
