// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

struct BatchRegisterCyberIdParams {
    string cid;
    address to;
    bool setReverse;
}

interface ICyberID {
    function privilegedRegister(
        BatchRegisterCyberIdParams[] calldata params
    ) external;
}
