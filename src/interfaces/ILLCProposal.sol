pragma ton-solidity >= 0.47.0;

struct ProposalInfo {
    address creator;
    mapping(address => uint32) oldCustodians;
    mapping(address => uint32) newCustodians;
    uint128 votesFor;
    uint128 votesAgainst;
    uint128 votesTotal;
    uint128 votesNeeded;
    uint32 start;
    uint32 end;
}

 interface ILLCProposal{

  function createProposal(
        mapping(address => uint32) newCustodians
    ) external;

  function getProposals() external returns (ProposalInfo[]);
  function getVotes() external returns (mapping(uint32 => mapping(address => bool)));
  function vote(uint32 currentProposalIndex, bool value) external;

    }
