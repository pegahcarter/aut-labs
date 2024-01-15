// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

contract MockDAOExpander {
    mapping(address who => bool isMember) private _isMemberOfOriginalDAO;

    function addMember(address who) external {
        _isMemberOfOriginalDAO[who] = true;
    }

    function isMemberOfOriginalDAO(address who) external view returns (bool) {
        return _isMemberOfOriginalDAO[who];
    }
}