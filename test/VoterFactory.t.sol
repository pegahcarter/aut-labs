// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "test/BaseTest.t.sol";

contract VoterFactoryTest is BaseTest {
    
    function test_CreateVoter_succeeds() public {
        // create a new daoExpander and approve the tester address
        iNova = new MockNova();
        iNova.addMember(tester);
        assertTrue(iNova.isMember(tester));

        // ensure that there is no existing voter for the daoExpander
        assertTrue(!iVoterFactory.hasVoter(address(iNova)));

        // Create the new voter contract
        vm.prank(tester);
        address voter = iVoterFactory.createVoter(address(iNova), address(iVoteCalculator));

        // Validate state
        assertTrue(iVoterFactory.hasVoter(address(iNova)));
        assertEq({
            a: address(Voter(voter).iNova()),
            b: address(iNova),
            err: "iNova not set in voter"
        });
    }

    function test_CreateVoter_VoterAlreadyExistsForDao_reverts() public {
        // check the pre-existing voter created in BaseTest.t.sol
        assertTrue(iVoterFactory.hasVoter(address(iNova)));

        vm.expectRevert(VoterFactory.VoterAlreadyExistsForDao.selector);
        vm.prank(tester);
        iVoterFactory.createVoter(address(iNova), address(iVoteCalculator));
    }

    function test_CreateVoter_NotDaoMember_reverts() public {
        // create a new daoExpander without any approved members
        iNova = new MockNova();
        assertTrue(!iNova.isMember(tester));

        vm.expectRevert(VoterFactory.NotDaoMember.selector);
        iVoterFactory.createVoter(address(iNova), address(iVoteCalculator));
    }
}