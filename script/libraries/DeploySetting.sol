// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

contract DeploySetting {
    struct DeployParameters {
        address deployerContract;
        address protocolOwner;
        address treasuryReceiver;
        address entryPoint;
        address backendSigner;
        address protocolSafe;
        address timeLock;
        address protocolSafeV2;
    }

    DeployParameters internal deployParams;

    uint256 internal constant ETH = 1;
    uint256 internal constant POLYGON = 137;
    uint256 internal constant OPTIMISM = 10;
    uint256 internal constant ARBITRUM = 42161;
    uint256 internal constant BNB = 56;
    uint256 internal constant BASE = 8453;
    uint256 internal constant LINEA = 59144;
    uint256 internal constant NOVA = 42170;
    uint256 internal constant OPBNB = 204;
    uint256 internal constant SCROLL = 534352;
    uint256 internal constant MANTLE = 5000;
    uint256 internal constant BLAST = 81457;
    uint256 internal constant CYBER = 7560;

    uint256 internal constant SEPOLIA = 11155111;
    uint256 internal constant GOERLI = 5;
    uint256 internal constant MUMBAI = 80001;
    uint256 internal constant OP_GOERLI = 420;
    uint256 internal constant OP_SEPOLIA = 11155420;
    uint256 internal constant BASE_GOERLI = 84531;
    uint256 internal constant BASE_SEPOLIA = 84532;
    uint256 internal constant LINEA_GOERLI = 59140;
    uint256 internal constant SCROLL_SEPOLIA = 534351;
    uint256 internal constant ARBITRUM_GOERLI = 421613;
    uint256 internal constant BNBT = 97;
    uint256 internal constant OPBNB_TESTNET = 5611;
    uint256 internal constant MANTLE_TESTENT = 5001;
    uint256 internal constant BLAST_SEPOLIA = 168587773;
    uint256 internal constant CYBER_TESTNET = 111557560;
    uint256 internal constant AMOY = 80002;
    uint256 internal constant IMX_TESTNET = 13473;
    uint256 internal constant ODYSSEY_TESTNET = 911867;

    function _setDeployParams() internal {
        if (
            block.chainid == MUMBAI ||
            block.chainid == BASE_GOERLI ||
            block.chainid == OP_GOERLI ||
            block.chainid == LINEA_GOERLI ||
            block.chainid == BNBT ||
            block.chainid == ARBITRUM_GOERLI ||
            block.chainid == OPBNB_TESTNET ||
            block.chainid == SCROLL_SEPOLIA ||
            block.chainid == GOERLI ||
            block.chainid == SEPOLIA ||
            block.chainid == MANTLE_TESTENT ||
            block.chainid == BLAST_SEPOLIA ||
            block.chainid == BASE_SEPOLIA ||
            block.chainid == OP_SEPOLIA ||
            block.chainid == CYBER_TESTNET ||
            block.chainid == AMOY ||
            block.chainid == IMX_TESTNET
        ) {
            deployParams.deployerContract = address(
                0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f
            );
            deployParams.protocolOwner = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.treasuryReceiver = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.entryPoint = address(
                0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
            );
            deployParams.backendSigner = address(
                0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F
            );
        } else if (block.chainid == POLYGON) {
            deployParams.deployerContract = address(
                0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f
            );
            deployParams.entryPoint = address(
                0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
            );
            deployParams.protocolOwner = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.treasuryReceiver = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.protocolSafe = address(
                0xAd09648A3b2e725d606c6440Ef3D1FB9693BAC1B
            );
            deployParams.backendSigner = address(
                0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
            );
        } else if (block.chainid == LINEA) {
            deployParams.deployerContract = address(
                0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f
            );
            deployParams.entryPoint = address(
                0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
            );
            deployParams.protocolOwner = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.treasuryReceiver = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.protocolSafe = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.backendSigner = address(
                0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
            );
        } else if (block.chainid == BNB) {
            deployParams.deployerContract = address(
                0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f
            );
            deployParams.entryPoint = address(
                0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
            );
            deployParams.protocolOwner = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.treasuryReceiver = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.backendSigner = address(
                0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
            );
            deployParams.protocolSafe = address(
                0xf9E12df9428F1a15BC6CfD4092ADdD683738cE96
            );
            deployParams.timeLock = address(
                0x3c84a5d37aF5b8Cc435D9c8C1994deBa40fC9c19
            );
            deployParams.protocolSafeV2 = address(
                0x4729A8F1FEc3b1353a751ce0143Fb16d119f706a
            );
        } else if (block.chainid == OPTIMISM) {
            deployParams.deployerContract = address(
                0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f
            );
            deployParams.entryPoint = address(
                0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
            );
            deployParams.protocolOwner = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.treasuryReceiver = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.backendSigner = address(
                0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
            );
            deployParams.protocolSafe = address(
                0x3c9A8527B4a1555d93D092212EF2aee7176b6ef4
            );
            deployParams.timeLock = address(
                0xCd78e2AB0F5363A5c3835C0423fa4055baCf91D6
            );
            deployParams.protocolSafeV2 = address(
                0x2f199646760aE75d423F4E98bb5249207ED1DC15
            );
        } else if (block.chainid == NOVA) {
            deployParams.deployerContract = address(
                0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f
            );
        } else if (block.chainid == ETH) {
            deployParams.deployerContract = address(
                0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f
            );
            deployParams.entryPoint = address(
                0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
            );
            deployParams.protocolOwner = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.treasuryReceiver = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.backendSigner = address(
                0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
            );
            deployParams.protocolSafe = address(
                0x91D60cd0f1F03442Dc899c9bD0592CF5F3aAb58d
            );
            deployParams.timeLock = address(
                0x81759AdbF5520aD94da10991DfA29Ff147d3337b
            );
            deployParams.protocolSafeV2 = address(
                0x455DB34c99A866489F3ac63fa2F068c726BC286b
            );
        } else if (block.chainid == BASE) {
            deployParams.deployerContract = address(
                0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f
            );
            deployParams.entryPoint = address(
                0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
            );
            deployParams.protocolOwner = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.treasuryReceiver = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.backendSigner = address(
                0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
            );
            deployParams.protocolSafe = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
        } else if (block.chainid == ARBITRUM) {
            deployParams.deployerContract = address(
                0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f
            );
            deployParams.entryPoint = address(
                0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
            );
            deployParams.protocolOwner = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.treasuryReceiver = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.backendSigner = address(
                0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
            );
            deployParams.protocolSafe = address(
                0x712ED050b30F3d952376FF8fb7F63ee815f7a757
            );
        } else if (block.chainid == OPBNB) {
            deployParams.deployerContract = address(
                0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f
            );
            deployParams.entryPoint = address(
                0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
            );
            deployParams.protocolOwner = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.treasuryReceiver = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.backendSigner = address(
                0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
            );
        } else if (block.chainid == SCROLL) {
            deployParams.deployerContract = address(
                0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f
            );
            deployParams.entryPoint = address(
                0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
            );
            deployParams.protocolOwner = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.treasuryReceiver = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.backendSigner = address(
                0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
            );
        } else if (block.chainid == MANTLE) {
            deployParams.deployerContract = address(
                0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f
            );
            deployParams.entryPoint = address(
                0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
            );
            deployParams.protocolOwner = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.treasuryReceiver = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.backendSigner = address(
                0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
            );
        } else if (block.chainid == BLAST) {
            deployParams.deployerContract = address(
                0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f
            );
            deployParams.entryPoint = address(
                0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
            );
            deployParams.protocolOwner = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.treasuryReceiver = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.backendSigner = address(
                0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
            );
        } else if (block.chainid == CYBER) {
            deployParams.deployerContract = address(
                0x8eD1282a1aCE084De1E99E9Ce5ed68896C49d65f
            );
            deployParams.entryPoint = address(
                0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
            );
            deployParams.protocolOwner = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.treasuryReceiver = address(
                0x7884f7F04F994da14302a16Cf15E597e31eebECf
            );
            deployParams.backendSigner = address(
                0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
            );
        } else {
            revert("PARAMS_NOT_SET");
        }
    }
}
