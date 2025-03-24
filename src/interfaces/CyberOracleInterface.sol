// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CyberOracleInterface
 * @dev Interface for the CyberOracle price feed contract
 */
interface CyberOracleInterface {
    /**
     * @dev Emitted when the price answer is updated
     * @param current The new answer value
     * @param roundId The round ID where the update occurred
     * @param updatedAt The timestamp when the update occurred
     */
    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );

    /**
     * @dev Emitted when a new round is started
     * @param roundId The ID of the new round
     * @param startedBy The address that initiated the new round
     * @param startedAt The timestamp when the round started
     */
    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );

    // ============ Metadata Functions ============

    /**
     * @dev Returns the number of decimals used in the oracle's answers
     * @return The number of decimals
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns a description of the oracle
     * @return A string describing the oracle
     */
    function description() external view returns (string memory);

    /**
     * @dev Returns the version of the oracle
     * @return The version number
     */
    function version() external view returns (uint256);

    // ============ Historical Data Functions ============

    /**
     * @dev Returns the price answer for a specific round
     * @param _roundId The round ID to get the answer for
     * @return The price answer for the specified round
     */
    function getAnswer(uint256 _roundId) external view returns (int256);

    /**
     * @dev Returns the timestamp for a specific round
     * @param _roundId The round ID to get the timestamp for
     * @return The timestamp for the specified round
     */
    function getTimestamp(uint256 _roundId) external view returns (uint256);

    /**
     * @dev Returns detailed data for a specific round
     * @param _roundId The round ID to get data for
     * @return roundId The round ID
     * @return answer The price answer
     * @return startedAt The timestamp when the round started
     * @return updatedAt The timestamp when the answer was last updated
     * @return answeredInRound The round ID in which the answer was computed
     */
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    // ============ Latest Data Functions ============

    /**
     * @dev Returns the latest price answer
     * @return The most recent price answer
     */
    function latestAnswer() external view returns (int256);

    /**
     * @dev Returns the latest round ID
     * @return The most recent round ID
     */
    function latestRound() external view returns (uint256);

    /**
     * @dev Returns the timestamp of the latest update
     * @return The timestamp of the most recent update
     */
    function latestTimestamp() external view returns (uint256);

    /**
     * @dev Returns detailed data for the latest round
     * @return roundId The round ID
     * @return answer The price answer
     * @return startedAt The timestamp when the round started
     * @return updatedAt The timestamp when the answer was last updated
     * @return answeredInRound The round ID in which the answer was computed
     */
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}
