// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

// Uniswap error selectors, used to surface information when swaps fail
// Pulled from @uniswap/universal-router/out/V3SwapRouter.sol/V3SwapRouter.json after compiling with forge
bytes32 constant V3_INVALID_SWAP = keccak256(hex"316cf0eb");
bytes32 constant V3_TOO_LITTLE_RECEIVED = keccak256(hex"39d35496");
bytes32 constant V3_TOO_MUCH_REQUESTED = keccak256(hex"739dbe52");
bytes32 constant V3_INVALID_AMOUNT_OUT = keccak256(hex"d4e0248e");
bytes32 constant V3_INVALID_CALLER = keccak256(hex"32b13d91");

struct SwapIntent {
    address tokenIn;
    address tokenOut;
    uint256 tokenInAmount;
    uint256 tokenOutAmount;
    address payable recipient;
    uint256 deadline;
    uint24 poolFeesTier;
}

struct ERC20PermitData {
    address currency;
    uint256 amount;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/*
 * @title ICyberVault
 * @author CyberConnect
 */
interface ICyberVault {
    /*//////////////////////////////////////////////////////////////
                            EVENT
    //////////////////////////////////////////////////////////////*/
    event Deposit(address to, uint256 amount);
    event Withdraw(address to, uint256 amount);
    event DepositERC20(address to, address currency, uint256 amount);
    event WithdrawERC20(address to, address currency, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            ERROR
    //////////////////////////////////////////////////////////////*/
    // @notice Raised when the permit signature is invalid
    error InvalidPermitSignature();

    // @notice Raised when a swap fails and returns a reason string
    // @param reason The error reason returned from the swap
    error SwapFailedString(string reason);

    // @notice Raised when a swap fails and returns another error
    // @param reason The error reason returned from the swap
    error SwapFailedBytes(bytes reason);

    /*//////////////////////////////////////////////////////////////
                            FUNCTION
    //////////////////////////////////////////////////////////////*/

    // deposit recipient currency token with pre-approve tx, will check the allowance before transfer
    // @param depositTo the address that deposit to
    // @param amount the token amount
    function depositPreApprove(address depositTo, uint256 amount) external;

    // deposit recipient currency token with permit signature, will permit token before transfer in this transaction
    // @param depositTo the address that deposit to
    // @param _permit the permit signature data
    function depositWithPermit(
        address depositTo,
        ERC20PermitData calldata _permit
    ) external;

    // swap native currency to recipient currency using UniswapV3, then deposit to recipient
    // @param depositTo the address that deposit to
    // @param _intent the swap intent
    function swapNativeAndDeposit(
        address depositTo,
        SwapIntent calldata _intent
    ) external payable;

    // swap ERC20 currency to recipient currency using UniswapV3 with pre-approve tx, will check the allowance before swap
    // @param depositTo the address that deposit to
    // @param _intent the swap intent
    function swapERC20PreApproveAndDeposit(
        address depositTo,
        SwapIntent calldata _intent
    ) external;

    // swap ERC20 currency to recipient currency using UniswapV3 with permit signature, will permit token before swap in this transaction
    // @param depositTo the address that deposit to
    // @param _intent the swap intent
    function swapERC20WithPermitAndDeposit(
        address depositTo,
        SwapIntent calldata _intent,
        ERC20PermitData calldata _permit
    ) external;
}
