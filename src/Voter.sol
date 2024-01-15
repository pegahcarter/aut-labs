// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import { IDAOExpander} from "@aut-labs/contracts/expander/interfaces/IDAOExpander.sol";
import { IVoteCalculator } from "src/interfaces/IVoteCalculator.sol";

/// TODO: natspec
contract Voter {

    IDAOExpander public immutable iDaoExpander;
    IVoteCalculator public immutable iVoteCalculator;
    uint256 public proposalId;

    struct Proposal {
        uint256 startTime;
        uint256 endTime;
        string metadata;
        uint256 yes;
        uint256 no;
    }
    mapping(uint256 _proposalId => Proposal proposal) public proposals;

    mapping(address member => mapping(uint256 _proposalId => bool voted)) public hasVoted;

    constructor(address _daoExpander, address _voteCalculator) {
        iDaoExpander = IDAOExpander(_daoExpander);
        iVoteCalculator = IVoteCalculator(_voteCalculator);
    }

    function propose(
        uint256 _startTime,
        uint256 _endTime,
        string calldata _metadata
    ) external returns (uint256 _proposalId) {
        // Revert if the sender is not a member of the dao
        if (!iDaoExpander.isMemberOfOriginalDAO(msg.sender)) revert NotDaoMember();

        /// @dev may cause issues for proposals with short time windows
        if (_startTime < block.timestamp) revert InvalidStartTime();
        if (_startTime >= _endTime) revert InvalidDuration();

        // Increment proposalId count
        _proposalId = ++proposalId;

        Proposal memory proposal = Proposal({
            startTime: _startTime,
            endTime: _endTime,
            metadata: _metadata,
            yes: 0,
            no: 0
        });

        proposals[_proposalId] = proposal;

        emit Proposed({
            _sender: msg.sender,
            _proposalId: _proposalId,
            _startTime: _startTime,
            _endTime: _endTime,
            _metadata: _metadata
        });
    }


    function vote(
        uint256 _proposalId,
        bool _yes
    ) external {
        Proposal storage proposal = proposals[_proposalId];
        if (
            !_isProposalActive({
                _timestamp: block.timestamp,
                _startTime: proposal.startTime,
                _endTime: proposal.endTime
            })
        ) revert InactiveProposal();

        if (hasVoted[msg.sender][_proposalId]) revert CannotVoteTwice();

        uint256 weight = iVoteCalculator.weights(msg.sender);

        // Increment total votes to the proposal
        _yes ? 
            proposal.yes += weight :
            proposal.no += weight;

        // Update vote state for user
        hasVoted[msg.sender][_proposalId] = true;

        emit Voted({
            _sender: msg.sender,
            _proposalId: _proposalId,
            _yes: _yes,
            _weight: weight
        });
    }

    function isProposalActive(uint256 _proposalId) public view returns (bool active) {
        Proposal memory proposal = proposals[_proposalId];
        active = _isProposalActive({
            _timestamp: block.timestamp,
            _startTime: proposal.startTime,
            _endTime: proposal.endTime
        });
    }

    function _isProposalActive(
        uint256 _timestamp,
        uint256 _startTime,
        uint256 _endTime
    ) internal pure returns (bool active) {
        active = (_timestamp >= _startTime && _timestamp <= _endTime);
    }

    function getProposal(uint256 _proposalId) external view returns (Proposal memory proposal) {
        proposal = proposals[_proposalId];
    }

    function getActiveProposalIDs() external view returns (uint256[] memory) {
        uint256 _proposalId = proposalId; // gas
        /// @dev Temporary proposal array to hold active proposal ids
        uint256[] memory proposalIds = new uint256[](_proposalId);
        uint256 numActiveProposals;

        // loop through all posted proposals
        for (uint256 i=_proposalId; i > 0;) {
            if (isProposalActive(i)) {
                // add live proposal to tempoary proposal array
                proposalIds[numActiveProposals] = i;

                unchecked {
                    ++numActiveProposals;
                }
            }
            
            unchecked {
                --i;
            }
        }

        /// @dev proposal array to return to caller
        uint256[] memory activeProposalIds = new uint256[](numActiveProposals);

        // fill up array with values found from first loop
        for (uint256 i=0; i < numActiveProposals;) {
            activeProposalIds[i] = proposalIds[i];

            unchecked {
                ++i;
            }
        }

        return activeProposalIds;
    }

    error CannotVoteTwice();
    error InactiveProposal();
    error NotDaoMember();
    error InvalidDuration();
    error InvalidStartTime();

    event Proposed(address indexed _sender, uint256 _proposalId, uint256 _startTime, uint256 _endTime, string _metadata);
    event Voted(address indexed _sender, uint256 indexed _proposalId, bool _yes, uint256 _weight);
}
