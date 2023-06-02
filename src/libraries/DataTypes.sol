// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library DataTypes {
    enum Category {
        Essence,
        Content,
        W3ST
    }

    enum ContentType {
        Content,
        Comment,
        Share
    }

    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct RegisterEssenceParams {
        string name;
        string symbol;
        string tokenURI;
        address mw;
        bool transferable;
    }

    struct PublishContentParams {
        string tokenURI;
        address mw;
        bool transferable;
    }

    struct ShareParams {
        address accountShared;
        uint256 idShared;
    }

    struct IssueW3stParams {
        string tokenURI;
        address mw;
        bool transferable;
    }

    struct EssenceStruct {
        address essence;
        address mw;
        string name;
        string symbol;
        string tokenURI;
        bool transferable;
    }

    struct AccountStruct {
        uint256 essenceCount;
        address w3st;
        uint256 w3stIdx;
        address content;
        uint256 contentIdx;
    }

    struct ContentStruct {
        address mw;
        string tokenURI;
        bool transferable;
        address srcAccount;
        uint256 srcId;
        ContentType contentType;
    }

    struct W3stStruct {
        address mw;
        string tokenURI;
        bool transferable;
    }

    struct CollectParams {
        address account;
        uint256 id;
        uint256 amount;
        Category category;
    }
}
