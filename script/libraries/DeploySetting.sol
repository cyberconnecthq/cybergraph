// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

contract DeploySetting {
    struct DeployParameters {
        address deployerContract;
    }

    DeployParameters internal deployParams;

    uint256 internal constant POLYGON = 137;
    uint256 internal constant MUMBAI = 80001;

    function _setDeployParams() internal {
        if (block.chainid == MUMBAI) {
            deployParams.deployerContract = address(
                0x526010620cAB87A4afD0599914Bc57aac095Dd34
            );
        } else {
            revert("PARAMS_NOT_SET");
        }
    }
}
