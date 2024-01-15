// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import { IDAOExpander} from "@aut-labs/contracts/expander/interfaces/IDAOExpander.sol";
import { Voter } from "src/Voter.sol";

contract VoterFactory { 
    mapping(address daoExpander => address voter) public daoExpanderToVoter;

    function hasVoter(address _daoExpander) public view returns (bool) {
        return daoExpanderToVoter[_daoExpander] != address(0);
    }

    error NotDaoMember();
    error VoterAlreadyExistsForDao();
    event CreateVoter(address indexed _sender, address indexed _daoExpander, address _voter);

    /// @dev _voteCalculator is a mock external contract and will need additional validation checks.
    function createVoter(address _daoExpander, address _voteCalculator) external returns (address voter) {
        if (hasVoter(_daoExpander)) revert VoterAlreadyExistsForDao();
        if (!IDAOExpander(_daoExpander).isMemberOfOriginalDAO(msg.sender)) revert NotDaoMember();

        voter = address(new Voter(_daoExpander, _voteCalculator));

        daoExpanderToVoter[_daoExpander] = voter;

        emit CreateVoter({
            _sender: msg.sender,
            _daoExpander: _daoExpander,
            _voter: voter
        });
    }
}
