// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "test/BaseTest.t.sol";

contract VoterFactoryTest is BaseTest {
    
    function test_CreateVoter_succeeds() public {
        // create a new daoExpander and approve the tester address
        iDaoExpander = new MockDAOExpander();
        iDaoExpander.addMember(tester);
        assertTrue(iDaoExpander.isMemberOfOriginalDAO(tester));

        // ensure that there is no existing voter for the daoExpander
        assertTrue(!iVoterFactory.hasVoter(address(iDaoExpander)));

        // Create the new voter contract
        vm.prank(tester);
        address voter = iVoterFactory.createVoter(address(iDaoExpander), address(iVoteCalculator));

        // Validate state
        assertTrue(iVoterFactory.hasVoter(address(iDaoExpander)));
        assertEq({
            a: address(Voter(voter).iDaoExpander()),
            b: address(iDaoExpander),
            err: "iDaoExpander not set in voter"
        });
    }

    function test_CreateVoter_VoterAlreadyExistsForDao_reverts() public {
        // check the pre-existing voter created in BaseTest.t.sol
        assertTrue(iVoterFactory.hasVoter(address(iDaoExpander)));

        vm.expectRevert(VoterFactory.VoterAlreadyExistsForDao.selector);
        vm.prank(tester);
        iVoterFactory.createVoter(address(iDaoExpander), address(iVoteCalculator));
    }

    function test_CreateVoter_NotDaoMember_reverts() public {
        // create a new daoExpander without any approved members
        iDaoExpander = new MockDAOExpander();
        assertTrue(!iDaoExpander.isMemberOfOriginalDAO(tester));

        vm.expectRevert(VoterFactory.NotDaoMember.selector);
        iVoterFactory.createVoter(address(iDaoExpander), address(iVoteCalculator));
    }
}