// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

contract MockVoteCalculator {
    mapping(address who => uint256 weight) public weights;

    function addWeight(address who, uint256 weight) external {
        weights[who] = weight;
    }
}