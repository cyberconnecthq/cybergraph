// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "../interfaces/IBlast.sol";

contract BlastProxy is IBlast {
    IBlast public blast;
    address private immutable blastProxySingleton;

    constructor() {
        blast = IBlast(BLAST);
        blastProxySingleton = address(this);
    }

    modifier delegateCallOnly() {
        require(
            address(this) != blastProxySingleton,
            "should only be called via delegatecall"
        );
        _;
    }

    // configure
    function configureContract(
        address contractAddress,
        YieldMode _yield,
        GasMode gasMode,
        address governor
    ) external override delegateCallOnly {
        blast.configureContract(contractAddress, _yield, gasMode, governor);
    }

    function configure(
        YieldMode _yield,
        GasMode gasMode,
        address governor
    ) external override delegateCallOnly {
        blast.configure(_yield, gasMode, governor);
    }

    // base configuration options
    function configureClaimableYield() external override delegateCallOnly {
        blast.configureClaimableYield();
    }

    function configureClaimableYieldOnBehalf(
        address contractAddress
    ) external override delegateCallOnly {
        blast.configureClaimableYieldOnBehalf(contractAddress);
    }

    function configureAutomaticYield() external override delegateCallOnly {
        blast.configureAutomaticYield();
    }

    function configureAutomaticYieldOnBehalf(
        address contractAddress
    ) external override delegateCallOnly {
        blast.configureAutomaticYieldOnBehalf(contractAddress);
    }

    function configureVoidYield() external override delegateCallOnly {
        blast.configureVoidYield();
    }

    function configureVoidYieldOnBehalf(
        address contractAddress
    ) external override delegateCallOnly {
        blast.configureVoidYieldOnBehalf(contractAddress);
    }

    function configureClaimableGas() external override delegateCallOnly {
        blast.configureClaimableGas();
    }

    function configureClaimableGasOnBehalf(
        address contractAddress
    ) external override delegateCallOnly {
        blast.configureClaimableGasOnBehalf(contractAddress);
    }

    function configureVoidGas() external override delegateCallOnly {
        blast.configureVoidGas();
    }

    function configureVoidGasOnBehalf(
        address contractAddress
    ) external override delegateCallOnly {
        blast.configureVoidGasOnBehalf(contractAddress);
    }

    function configureGovernor(
        address _governor
    ) external override delegateCallOnly {
        blast.configureGovernor(_governor);
    }

    function configureGovernorOnBehalf(
        address _newGovernor,
        address contractAddress
    ) external override delegateCallOnly {
        blast.configureGovernorOnBehalf(_newGovernor, contractAddress);
    }

    // claim yield
    function claimYield(
        address contractAddress,
        address recipientOfYield,
        uint256 amount
    ) external override delegateCallOnly returns (uint256) {
        return blast.claimYield(contractAddress, recipientOfYield, amount);
    }

    function claimAllYield(
        address contractAddress,
        address recipientOfYield
    ) external override delegateCallOnly returns (uint256) {
        return blast.claimAllYield(contractAddress, recipientOfYield);
    }

    // claim gas
    function claimAllGas(
        address contractAddress,
        address recipientOfGas
    ) external override delegateCallOnly returns (uint256) {
        return blast.claimAllGas(contractAddress, recipientOfGas);
    }

    function claimGasAtMinClaimRate(
        address contractAddress,
        address recipientOfGas,
        uint256 minClaimRateBips
    ) external override delegateCallOnly returns (uint256) {
        return
            blast.claimGasAtMinClaimRate(
                contractAddress,
                recipientOfGas,
                minClaimRateBips
            );
    }

    function claimMaxGas(
        address contractAddress,
        address recipientOfGas
    ) external override delegateCallOnly returns (uint256) {
        return blast.claimMaxGas(contractAddress, recipientOfGas);
    }

    function claimGas(
        address contractAddress,
        address recipientOfGas,
        uint256 gasToClaim,
        uint256 gasSecondsToConsume
    ) external override delegateCallOnly returns (uint256) {
        return
            blast.claimGas(
                contractAddress,
                recipientOfGas,
                gasToClaim,
                gasSecondsToConsume
            );
    }

    // read functions
    function readClaimableYield(
        address contractAddress
    ) external view override returns (uint256) {
        return blast.readClaimableYield(contractAddress);
    }

    function readYieldConfiguration(
        address contractAddress
    ) external view override returns (uint8) {
        return blast.readYieldConfiguration(contractAddress);
    }

    function readGasParams(
        address contractAddress
    )
        external
        view
        override
        returns (
            uint256 etherSeconds,
            uint256 etherBalance,
            uint256 lastUpdated,
            GasMode
        )
    {
        return blast.readGasParams(contractAddress);
    }
}
