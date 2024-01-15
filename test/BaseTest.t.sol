// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import { VoterFactory } from "src/VoterFactory.sol";
import { Voter } from "src/Voter.sol";
import { MockDAOExpander } from "test/mocks/MockDAOExpander.sol";
import { MockVoteCalculator } from "test/mocks/MockVoteCalculator.sol";

contract BaseTest is Test {
    address internal tester = address(0x1);
    address internal tester2 = address(0x2);
    address internal tester3 = address(0x3);

    VoterFactory public iVoterFactory;
    Voter public iVoter;
    MockDAOExpander public iDaoExpander;
    MockVoteCalculator public iVoteCalculator;

    function setUp() public {
        iVoterFactory = new VoterFactory();
        iDaoExpander = new MockDAOExpander();
        iVoteCalculator = new MockVoteCalculator();

        // approve tester to daoExpander
        iDaoExpander.addMember(tester);

        // create an initial instance of the Voter
        vm.prank(tester);
        iVoter = Voter(iVoterFactory.createVoter(address(iDaoExpander), address(iVoteCalculator)));
    }
}