// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title VotingContract
 * @dev 간단한 5인 후보 투표 관리 컨트랙트
 *      - 배포 시점 기준 시작‧종료 시간을 설정하여 타임락(timelock) 조건 구현
 *      - 주소당 1회 투표만 허용(modifier)
 *      - 투표 성공 시 event 발생
 *      - 투표 완료 주소와 시점을 영구 기록
 */
contract VotingContract {
    // ────────────────────────────────
    // 데이터 구조 
    // ────────────────────────────────
    struct VoterInfo {
        bool voted;            // 중복 투표 방지 플래그
        uint8 candidateId;     // 선택한 후보(0‒4)
        uint256 timestamp;     // 투표 완료 시각
    }

    // 후보 5명은 하드코딩된 배열로 관리
    string[5] public candidates = [
        "Alice",
        "Bob",
        "Charlie",
        "Dave",
        "Eve"
    ];

    // 후보별 득표수   candidateId ⇒ count
    mapping(uint8 => uint256) public voteCounts;

    // 유권자별 투표 이력   voterAddress ⇒ VoterInfo
    mapping(address => VoterInfo) public voters;

    // 투표 완료 주소 목록 (필요 시 enumerate)
    address[] public voterAddresses;

    // 타임락용 변수
    uint256 public immutable startTime;   // 투표 시작 시각
    uint256 public immutable endTime;     // 투표 종료 시각

    // ────────────────────────────────
    // 이벤트
    // ────────────────────────────────
    event VoteCast(address indexed voter, uint8 indexed candidateId, uint256 timestamp);

    // ────────────────────────────────
    // 생성자
    // ────────────────────────────────
    /**
     * @param _startDelaySeconds 배포 후 투표 시작까지 지연 시간(초)
     * @param _durationSeconds   투표 가능 기간(초)
     */
    constructor(uint256 _startDelaySeconds, uint256 _durationSeconds) {
        require(_durationSeconds > 0, "Duration must be > 0");
        startTime = block.timestamp + _startDelaySeconds;
        endTime   = startTime + _durationSeconds;
    }

    // ────────────────────────────────
    // 수정자(modifier)
    // ───────────────────────────────
    modifier afterStart() {
        require(block.timestamp >= startTime, "Voting not started yet");
        _;
    }

    modifier beforeEnd() {
        require(block.timestamp <= endTime, "Voting period has ended");
        _;
    }

    modifier onlyOnce() {
        require(!voters[msg.sender].voted, "Already voted");
        _;
    }

    // ────────────────────────────────
    // 주요 기능
    // ────────────────────────────────

    /**
     * @notice 후보에게 1표를 투표합니다.
     * @param candidateId 후보 인덱스(0~4)
     */
    function vote(uint8 candidateId) external afterStart beforeEnd onlyOnce {
        require(candidateId < candidates.length, "Invalid candidate");

        // 기록 업데이트
        voters[msg.sender] = VoterInfo({
            voted: true,
            candidateId: candidateId,
            timestamp: block.timestamp
        });
        voteCounts[candidateId] += 1;
        voterAddresses.push(msg.sender);

        emit VoteCast(msg.sender, candidateId, block.timestamp);
    }

    /**
     * @dev 전체 득표수가 가장 높은 후보와 득표수를 반환
     */
    function leadingCandidate() external view returns (string memory name, uint256 votes_) {
        uint256 maxVotes = 0;
        uint8 leader = 0;
        for (uint8 i = 0; i < candidates.length; i++) {
            if (voteCounts[i] > maxVotes) {
                maxVotes = voteCounts[i];
                leader = i;
            }
        }
        return (candidates[leader], maxVotes);
    }

    /**
     * @dev 남은 투표 가능 시간을 초 단위로 반환; 이미 종료되었으면 0
     */
    function timeLeft() external view returns (uint256) {
        return block.timestamp >= endTime ? 0 : endTime - block.timestamp;
    }

    /**
     * @dev 투표자 전체 주소 목록을 반환 (프론트엔드 편의를 위해)
     */
    function getVoterAddresses() external view returns (address[] memory) {
        return voterAddresses;
    }
}
