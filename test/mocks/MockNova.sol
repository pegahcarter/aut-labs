// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

contract MockNova {
    mapping(address who => bool isMember) private _isMember;

    function addMember(address who) external {
        _isMember[who] = true;
    }

    function isMember(address who) external view returns (bool) {
        return _isMember[who];
    }
}