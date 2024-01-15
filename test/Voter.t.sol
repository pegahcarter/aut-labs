// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "test/BaseTest.t.sol";

contract VoterTest is BaseTest {

    function test_Voter_initialState() public {
        // Validate the Voter created in BaseTest.t.sol
        assertEq({
            a: 0,
            b: iVoter.proposalId(),
            err: "Voter proposal ID should equal 0"
        });
        assertEq({
            a: address(iDaoExpander),
            b: address(iVoter.iDaoExpander()),
            err: "Voter iDaoExpander incorrectly set"
        });

        Voter.Proposal memory proposal = iVoter.getProposal(1);
        assertEq({
            a: proposal.startTime,
            b: 0,
            err: "proposal startTime should be 0"
        });
        assertEq({
            a: proposal.endTime,
            b: 0,
            err: "proposal endTime should be 0"
        });
        assertEq({
            a: bytes(proposal.metadata).length,
            b: 0,
            err: "proposal metadata should be null"
        });
        assertEq({
            a: proposal.yes,
            b: 0,
            err: "proposal yes should be 0"
        });
        assertEq({
            a: proposal.no,
            b: 0,
            err: "proposal no should be 0"
        });
    }

    function test_Propose_succeeds() public {
        uint256 startTime = block.timestamp + 1;
        uint256 endTime = block.timestamp + 1 days;
        string memory metadata = "My Proposal is...";

        /// @dev tester is already member of the dao
        vm.prank(tester);
        uint256 proposalId = iVoter.propose({
            _startTime: startTime,
            _endTime: endTime,
            _metadata: metadata
        });
        Voter.Proposal memory proposal = iVoter.getProposal(proposalId);

        assertEq({
            a: iVoter.proposalId(),
            b: 1,
            err: "voter should have one proposal"
        });

        assertEq({
            a: proposal.startTime,
            b: startTime,
            err: "proposal startTime should be startTime"
        });
        assertEq({
            a: proposal.endTime,
            b: endTime,
            err: "proposal endTime should be endTime"
        });
        assertEq({
            a: keccak256(abi.encodePacked(proposal.metadata)),
            b: keccak256(abi.encodePacked(metadata)),
            err: "proposal metadata should updated"
        });
        assertEq({
            a: proposal.yes,
            b: 0,
            err: "proposal yes should be 0"
        });
        assertEq({
            a: proposal.no,
            b: 0,
            err: "proposal no should be 0"
        });
    }

    /// @dev this could lead to DoS if one DAO member goes rogue and submits 1000x proposals
    function test_Propose_Twice_succeeds() public {
        uint256 startTime = block.timestamp + 1;
        uint256 endTime = block.timestamp + 1 days;
        string memory metadata = "My Proposal is...";

        /// @dev tester is already member of the dao (set in BaseTest.t.sol)
        vm.startPrank(tester);
        iVoter.propose({
            _startTime: startTime,
            _endTime: endTime,
            _metadata: metadata
        });
        iVoter.propose({
            _startTime: startTime,
            _endTime: endTime,
            _metadata: metadata
        });
    }

    function test_Propose_NotDaoMember_reverts() public {
        assertTrue(!iDaoExpander.isMemberOfOriginalDAO(tester2));

        vm.expectRevert(Voter.NotDaoMember.selector);
        vm.prank(tester2);
        iVoter.propose({
            _startTime: block.timestamp + 1,
            _endTime: block.timestamp + 1 days,
            _metadata: ""});
    }

    function test_Propose_InvalidStartTime_reverts() public {
        vm.expectRevert(Voter.InvalidStartTime.selector);
        vm.prank(tester);
        iVoter.propose({
            _startTime: block.timestamp - 1, // before current timestamp
            _endTime: block.timestamp + 1 days,
            _metadata: ""});
    }

    function test_Propose_InvalidDuration_reverts() public {
        vm.expectRevert(Voter.InvalidDuration.selector);
        vm.prank(tester);
        iVoter.propose({
            _startTime: block.timestamp + 1,
            _endTime: block.timestamp + 1, // same as startTime
            _metadata: ""});
    }

    function test_Vote_succeeds() public {
        /// @dev setup: add other testers to dao
        iDaoExpander.addMember(tester2);
        iDaoExpander.addMember(tester3);

        /// @dev setup: give testers voting weights
        uint256 weight1 = 10;
        uint256 weight2 = 42;
        uint256 weight3 = 11;
        iVoteCalculator.addWeight(tester, weight1);
        iVoteCalculator.addWeight(tester2, weight2);
        iVoteCalculator.addWeight(tester3, weight3);

        // Given: a proposal has been made
        vm.prank(tester);
        uint256 proposalId = iVoter.propose({
            _startTime: block.timestamp + 1,
            _endTime: block.timestamp + 1 days,
            _metadata: ""
        });

        // Given: we are now in the acceptable voting time frame
        vm.roll(1);
        skip(10);

        // Tester 1 votes "yes" for the proposal
        vm.prank(tester);
        iVoter.vote({
            _proposalId: proposalId,
            _yes: true
        });
        assertTrue(iVoter.hasVoted(tester, proposalId));
        Voter.Proposal memory proposal = iVoter.getProposal(proposalId);
        assertEq({
            a: proposal.yes,
            b: weight1,
            err: "Proposal yes should equal weight1"
        });
        assertEq({
            a: proposal.no,
            b: 0,
            err: "Proposal no should be 0"
        });

        // Tester 2 votes "no" for the proposal
        vm.prank(tester2);
        iVoter.vote({
            _proposalId: proposalId,
            _yes: false
        });
        assertTrue(iVoter.hasVoted(tester, proposalId));
        assertTrue(iVoter.hasVoted(tester2, proposalId));
        proposal = iVoter.getProposal(proposalId);
        assertEq({
            a: proposal.yes,
            b: weight1,
            err: "Proposal yes should equal weight1"
        });
        assertEq({
            a: proposal.no,
            b: weight2,
            err: "Proposal no should be 0"
        });

        // tester3 votes "yes" for the proposal
        vm.prank(tester3);
        iVoter.vote({
            _proposalId: proposalId,
            _yes: true
        });
        assertTrue(iVoter.hasVoted(tester, proposalId));
        assertTrue(iVoter.hasVoted(tester2, proposalId));
        assertTrue(iVoter.hasVoted(tester3, proposalId));
        proposal = iVoter.getProposal(proposalId);
        assertEq({
            a: proposal.yes,
            b: weight1 + weight3,
            err: "Proposal yes should equal weight1 + weight3"
        });
        assertEq({
            a: proposal.no,
            b: weight2,
            err: "Proposal no should equal weight2"
        });
    }

    function test_Vote_InactiveProposal_reverts() public {
        // Given: tester 1 creates a proposal
        vm.startPrank(tester);
        uint256 proposalId = iVoter.propose({
            _startTime: block.timestamp + 1,
            _endTime: block.timestamp + 1 days,
            _metadata: ""
        });

        // reverts when voting before the proposal is live
        vm.expectRevert(Voter.InactiveProposal.selector);
        iVoter.vote({
            _proposalId: proposalId,
            _yes: true
        });

        // fast-fwd to after the proposal is live
        vm.roll(1);
        skip(1 days + 1);

        // reverts when voting after the proposal is live
        vm.expectRevert(Voter.InactiveProposal.selector);
        iVoter.vote({
            _proposalId: proposalId,
            _yes: true
        });
    }

    function test_Vote_CannotVoteTwice_reverts() public {
        // Given: tester creates a proposal
        vm.startPrank(tester);
        uint256 proposalId = iVoter.propose({
            _startTime: block.timestamp + 1,
            _endTime: block.timestamp + 1 days,
            _metadata: ""
        });

        // fast-fwd to when proposal is live
        vm.roll(1);
        skip(10);

        // tester votes once
        iVoter.vote({
            _proposalId: proposalId,
            _yes: true
        });

        // reverts when tester votes again
        vm.expectRevert(Voter.CannotVoteTwice.selector);
        iVoter.vote({
            _proposalId: proposalId,
            _yes: false
        });
    }

    function test_GetActiveProposalIDs_succeeds() public {
        uint256[] memory activeProposalIds = iVoter.getActiveProposalIDs();
        assertEq({
            a: activeProposalIds.length,
            b: 0,
            err: "There should be no active proposals"
        });

        // tester creates one proposal
        vm.startPrank(tester);
        uint256 proposalId1 = iVoter.propose({
            _startTime: block.timestamp + 1,
            _endTime: block.timestamp + 1 days,
            _metadata: ""
        });
        
        // Still 0 until proposal is live
        activeProposalIds = iVoter.getActiveProposalIDs();
        assertEq({
            a: activeProposalIds.length,
            b: 0,
            err: "The first proposal should not be active"
        });

        // proposal is live
        vm.roll(1);
        skip(10);

        activeProposalIds = iVoter.getActiveProposalIDs();
        assertEq({
            a: activeProposalIds.length,
            b: 1,
            err: "there should be one active proposal"
        });
        assertEq({
            a: activeProposalIds[0],
            b: proposalId1,
            err: "activeProposalIds[0] should equal proposalId1"
        });
    }
}
