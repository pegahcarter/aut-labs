// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import { INova } from "@aut-labs/contracts/nova/INova.sol";
import { Voter } from "src/Voter.sol";

contract VoterFactory { 
    mapping(address nova => address voter) public novaToVoter;

    function hasVoter(address _nova) public view returns (bool) {
        return novaToVoter[_nova] != address(0);
    }

    error NotDaoMember();
    error VoterAlreadyExistsForDao();
    event CreateVoter(address indexed _sender, address indexed _nova, address _voter);

    /// @dev _voteCalculator is a mock external contract and will need additional validation checks.
    function createVoter(address _nova, address _voteCalculator) external returns (address voter) {
        if (hasVoter(_nova)) revert VoterAlreadyExistsForDao();
        if (!INova(_nova).isMember(msg.sender)) revert NotDaoMember();

        voter = address(new Voter(_nova, _voteCalculator));

        novaToVoter[_nova] = voter;

        emit CreateVoter({
            _sender: msg.sender,
            _nova: _nova,
            _voter: voter
        });
    }
}
