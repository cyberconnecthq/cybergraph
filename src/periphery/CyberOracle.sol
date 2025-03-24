// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import "../interfaces/CyberOracleInterface.sol";

/**
 * @title CyberOracle
 * @author Cyber
 */
contract CyberOracle is
    CyberOracleInterface,
    Ownable,
    UUPSUpgradeable,
    Initializable
{
    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    // Mapping of round ID to price data
    mapping(uint80 => int256) private _answers;

    // Mapping of round ID to timestamp when the price was updated
    mapping(uint80 => uint256) private _updatedTimestamps;

    // Mapping of round ID to timestamp when the round started
    mapping(uint80 => uint256) private _startedTimestamps;

    // Stores the latest round ID
    uint80 private _latestRound;

    // Stores authorized data providers who can update price data
    mapping(address => bool) private _dataProviders;

    // Decimals for price representation
    uint8 private _decimals;

    // Price feed description
    string private _description;

    // Oracle version
    uint256 private _version;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when a data provider is added or removed
     * @param provider Address of the data provider
     * @param isAuthorized Whether the provider is authorized or not
     */
    event DataProviderUpdated(address indexed provider, bool isAuthorized);

    /**
     * @notice Emitted when oracle configuration is updated
     * @param decimals New decimals value
     * @param description New description
     * @param version New version
     */
    event OracleConfigUpdated(
        uint8 decimals,
        string description,
        uint256 version
    );

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Ensures the caller is an authorized data provider
     */
    modifier onlyDataProvider() {
        require(_dataProviders[msg.sender], "UNAUTHORIZED_PROVIDER");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR & INITIALIZER
    //////////////////////////////////////////////////////////////*/
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the oracle contract
     * @param owner Address of the contract owner
     * @param decimals Number of decimals used for price representation
     * @param description Description of the price feed
     */
    function initialize(
        address owner,
        uint8 decimals,
        string memory description
    ) external initializer {
        _transferOwnership(owner);
        _decimals = decimals;
        _description = description;
        _version = 1;

        emit OracleConfigUpdated(decimals, description, 1);
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc CyberOracleInterface
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @inheritdoc CyberOracleInterface
     */
    function description() external view returns (string memory) {
        return _description;
    }

    /**
     * @inheritdoc CyberOracleInterface
     */
    function version() external view returns (uint256) {
        return _version;
    }

    /**
     * @inheritdoc CyberOracleInterface
     */
    function getAnswer(uint256 roundId) external view returns (int256) {
        return _answers[uint80(roundId)];
    }

    /**
     * @inheritdoc CyberOracleInterface
     */
    function getTimestamp(uint256 roundId) external view returns (uint256) {
        return _updatedTimestamps[uint80(roundId)];
    }

    /**
     * @inheritdoc CyberOracleInterface
     */
    function latestAnswer() external view returns (int256) {
        return _answers[_latestRound];
    }

    /**
     * @inheritdoc CyberOracleInterface
     */
    function latestRound() external view returns (uint256) {
        return _latestRound;
    }

    /**
     * @inheritdoc CyberOracleInterface
     */
    function latestTimestamp() external view returns (uint256) {
        return _updatedTimestamps[_latestRound];
    }

    /**
     * @inheritdoc CyberOracleInterface
     */
    function getRoundData(
        uint80 roundId
    ) external view returns (uint80, int256, uint256, uint256, uint80) {
        return (
            roundId,
            _answers[roundId],
            _startedTimestamps[roundId],
            _updatedTimestamps[roundId],
            roundId
        );
    }

    /**
     * @inheritdoc CyberOracleInterface
     */
    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (
            _latestRound,
            _answers[_latestRound],
            _startedTimestamps[_latestRound],
            _updatedTimestamps[_latestRound],
            _latestRound
        );
    }

    /**
     * @notice Updates price data
     * @dev Can only be called by authorized data providers
     * @param answer The new price data
     * @param roundId Optional specific round ID to update. If 0, creates a new round.
     * @param timestamp The timestamp for this price update
     * @return The ID of the updated or new round
     */
    function updatePrice(
        int256 answer,
        uint80 roundId,
        uint256 timestamp
    ) external onlyDataProvider returns (uint80) {
        require(timestamp > 0, "INVALID_TIMESTAMP");

        if (roundId == 0) {
            // Create a new round (equivalent to previous updateAnswer)
            roundId = _latestRound + 1;

            _startedTimestamps[roundId] = timestamp;
            _updatedTimestamps[roundId] = timestamp;
            _answers[roundId] = answer;
            _latestRound = roundId;

            emit NewRound(roundId, msg.sender, timestamp);
        } else {
            // Update existing round (equivalent to previous updateRoundData)
            require(roundId <= _latestRound, "INVALID_ROUND_ID");
            require(_startedTimestamps[roundId] > 0, "ROUND_NOT_STARTED");

            _answers[roundId] = answer;
            _updatedTimestamps[roundId] = timestamp;
        }

        emit AnswerUpdated(answer, roundId, timestamp);
        return roundId;
    }

    /**
     * @notice Adds or removes a data provider
     * @dev Can only be called by the contract owner
     * @param provider Address of the data provider
     * @param isAuthorized Whether to authorize or revoke the provider
     */
    function setDataProvider(
        address provider,
        bool isAuthorized
    ) external onlyOwner {
        _dataProviders[provider] = isAuthorized;
        emit DataProviderUpdated(provider, isAuthorized);
    }

    /**
     * @notice Updates the oracle configuration
     * @dev Can only be called by the contract owner
     * @param decimals New decimals value
     * @param description New description
     * @param version New version number
     */
    function updateOracleConfig(
        uint8 decimals,
        string memory description,
        uint256 version
    ) external onlyOwner {
        _decimals = decimals;
        _description = description;
        _version = version;

        emit OracleConfigUpdated(decimals, description, version);
    }

    /**
     * @notice Checks if an address is an authorized data provider
     * @param provider Address to check
     * @return True if the address is an authorized data provider
     */
    function isDataProvider(address provider) external view returns (bool) {
        return _dataProviders[provider];
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc UUPSUpgradeable
     */
    function _authorizeUpgrade(address) internal view override {
        require(msg.sender == owner(), "ONLY_OWNER");
    }
}
