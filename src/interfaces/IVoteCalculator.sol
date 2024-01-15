// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

interface IVoteCalculator {
    function weights(address) external view returns (uint256);
    function addWeight(address, uint256) external;
}