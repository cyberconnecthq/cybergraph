// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library DataTypes {
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
    }

    struct CollectParams {
        address collector;
        address account;
        uint256 essenceId;
    }

    enum Category {
        Essence,
        Content,
        W3ST
    }
}
