// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract StackUp {
  enum PlayerQuestStatus {
    NOT_JOINED,
    JOINED,
    SUBMITTED
  }

  struct Quest {
    uint256 questId;
    uint256 numberOfPlayers;
    string title;
    uint8 reward;
    uint256 numberOfRewards;
    uint256 startTime;
    uint256 endTime;
  }

  address public admin;
  uint256 public nextQuestId;
  mapping(uint256 => Quest) public quests;
  mapping(address => mapping(uint256 => PlayerQuestStatus)) public playerQuestStatuses;

  constructor() {
    admin = msg.sender;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, "Only the admin can perform this action");
    _;
  }

  modifier questExists(uint256 questId) {
    require(quests[questId].reward != 0, "Quest does not exist");
    _;
  }

  modifier canJoinQuest(uint256 questId) {
    require(
      quests[questId].startTime <= block.timestamp && block.timestamp <= quests[questId].endTime,
      "Quest is not available to join"
    );
    _;
  }

  /**
   * @dev Creates a new quest with the provided details and start/end times.
   * @param title_ The title of the quest.
   * @param reward_ The reward value for completing the quest.
   * @param numberOfRewards_ The number of available rewards for the quest.
   * @param startTime_ The timestamp when the quest starts.
   * @param endTime_ The timestamp when the quest ends.
   */
  function createQuest(
    string calldata title_,
    uint8 reward_,
    uint256 numberOfRewards_,
    uint256 startTime_,
    uint256 endTime_
  ) external onlyAdmin {
    quests[nextQuestId] = Quest(
      nextQuestId,
      0,
      title_,
      reward_,
      numberOfRewards_,
      startTime_,
      endTime_
    );
    nextQuestId++;
  }

  /**
   * @dev Allows the admin to edit the details and time constraints of an existing quest.
   * @param questId The ID of the quest to be edited.
   * @param title_ The new title for the quest.
   * @param newReward The new reward for the quest.
   * @param newNumberOfRewards The new number of rewards for the quest.
   * @param newStartTime The new start time for the quest.
   * @param newEndTime The new end time for the quest.
   */
  function editQuest(
    uint256 questId,
    string calldata title_,
    uint8 newReward,
    uint256 newNumberOfRewards,
    uint256 newStartTime,
    uint256 newEndTime
  ) external onlyAdmin questExists(questId) {
    Quest storage quest = quests[questId];
    quest.title = title_;
    quest.reward = newReward;
    quest.numberOfRewards = newNumberOfRewards;
    quest.startTime = newStartTime;
    quest.endTime = newEndTime;
  }

  /**
   * @dev Allows the admin to delete an existing quest.
   * @param questId The ID of the quest to be deleted.
   */
  function deleteQuest(uint256 questId) external onlyAdmin questExists(questId) {
    delete quests[questId];
  }

  /**
   * @dev Allows a user to join a quest if it is available.
   * @param questId The ID of the quest to join.
   */
  function joinQuest(uint256 questId) external questExists(questId) canJoinQuest(questId) {
    require(
      playerQuestStatuses[msg.sender][questId] == PlayerQuestStatus.NOT_JOINED,
      "Player has already joined/submitted this quest"
    );
    playerQuestStatuses[msg.sender][questId] = PlayerQuestStatus.JOINED;

    Quest storage thisQuest = quests[questId];
    thisQuest.numberOfPlayers++;
  }

  /**
  * @dev Allows a user to submit a joined quest before the quest's end time.
  * @param questId The ID of the quest to submit.
  * @notice Users can only submit a quest if they have joined it and the quest's end time has not been reached.
  */
  function submitQuest(uint256 questId) external questExists(questId) {
    require(
      playerQuestStatuses[msg.sender][questId] == PlayerQuestStatus.JOINED,
      "Player must first join the quest"
    );
    require(
    quests[questId].endTime >= block.timestamp,
    "Quest submission deadline has passed"
    );
    playerQuestStatuses[msg.sender][questId] = PlayerQuestStatus.SUBMITTED;
  }
}
