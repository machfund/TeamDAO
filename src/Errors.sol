pragma ton-solidity >= 0.47.0;

library Errors {
    uint16 constant INVALID_CALLER = 100;
    uint16 constant INVALID_VALUE = 101;
    uint16 constant INVALID_ARGUMENTS = 102;
    uint16 constant CONTRACT_INITED = 103;
    uint16 constant PROPOSAL_VOTING_HAS_ENDED = 104;
    uint16 constant INVALID_VOTES = 105;
}
