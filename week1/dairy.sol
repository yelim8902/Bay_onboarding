// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Diary {
    // 기분을 나타내는 enum
    enum Mood { Good, Normal, Bad }

    // 일기 항목 구조체
    struct DiaryEntry {
        string title;
        string content;
        Mood mood;
        uint timestamp;
    }

    // 사용자별로 일기들을 저장하는 mapping
    mapping(address => DiaryEntry[]) private diaryList;

    // 일기 작성
    function writeDiary(string memory _title, string memory _content, Mood _mood) public {
        DiaryEntry memory entry = DiaryEntry({
            title: _title,
            content: _content,
            mood: _mood,
            timestamp: block.timestamp
        });

        diaryList[msg.sender].push(entry);
    }

    // 내가 쓴 전체 일기 가져오기
    function getMyDiaries() public view returns (DiaryEntry[] memory) {
        return diaryList[msg.sender];
    }

    // 기분으로 일기 필터링해서 가져오기
    function getMyDiariesByMood(Mood _mood) public view returns (DiaryEntry[] memory) {
        DiaryEntry[] memory all = diaryList[msg.sender];
        uint count = 0;

        // 먼저 조건에 맞는 일기 개수 세기
        for (uint i = 0; i < all.length; i++) {
            if (all[i].mood == _mood) {
                count++;
            }
        }

        // 그만큼 크기의 배열 만들고 다시 넣기
        DiaryEntry[] memory result = new DiaryEntry[](count);
        uint j = 0;

        for (uint i = 0; i < all.length; i++) {
            if (all[i].mood == _mood) {
                result[j] = all[i];
                j++;
            }
        }

        return result;
    }
}
