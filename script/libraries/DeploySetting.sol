// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

contract DeploySetting {
    struct DeployParameters {
        address deployerContract;
        address protocolOwner;
        address treasuryReceiver;
        address entryPoint;
    }

    DeployParameters internal deployParams;

    uint256 internal constant POLYGON = 137;
    uint256 internal constant MUMBAI = 80001;
    uint256 internal constant OP_GOERLI = 420;
    uint256 internal constant BASE_GOERLI = 84531;

    function _setDeployParams() internal {
        if (block.chainid == MUMBAI || block.chainid == BASE_GOERLI) {
            deployParams.deployerContract = address(
                0xF191131dAB798dD6c500816338d4B6EBC34825C7
            );
            deployParams.protocolOwner = address(
                0x526010620cAB87A4afD0599914Bc57aac095Dd34
            );
            deployParams.treasuryReceiver = address(
                0x526010620cAB87A4afD0599914Bc57aac095Dd34
            );
            deployParams.entryPoint = address(
                0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
            );
        } else if (block.chainid == OP_GOERLI) {
            deployParams.deployerContract = address(
                0xF191131dAB798dD6c500816338d4B6EBC34825C7
            );
        } else {
            revert("PARAMS_NOT_SET");
        }
    }
}
