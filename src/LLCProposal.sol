pragma ton-solidity >= 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/ILLCProposal.sol";

import "./Errors.sol";
import "./Fees.sol";


contract LLCProposal is ILLCProposal{
    ProposalInfo[] _proposals;
    ProposalInfo proposal;
    mapping(address => uint32) _custodians;
    uint32 _totalCustodians;
    mapping(uint32 => mapping(address => bool)) _votes;

    function createProposal(
        mapping(address => uint32) newCustodians
    ) external override {
        require(msg.sender != address(0), Errors.INVALID_CALLER);
        require(_custodians.exists(msg.sender), Errors.INVALID_CALLER);
        require(msg.value >= Fees.PROCESS, Errors.INVALID_VALUE);

        optional(address, uint32) oCustodian = _custodians.min();
        uint32 custodiansTotal = 0;
        uint32 totalShare = 0;
        while (oCustodian.hasValue()) {
            (address addrCustodian, uint32 shareCustodian) = oCustodian.get();
            custodiansTotal++; 
            totalShare += shareCustodian;
            oCustodian = _custodians.next(addrCustodian);
        }
        require(totalShare == 100, Errors.INVALID_VALUE);

        uint32 votesNeeded;
        if (custodiansTotal % 2 == 0) {
            votesNeeded = custodiansTotal / 2 + 1;
        } else { 
            votesNeeded = (custodiansTotal + 1) / 2; 
        }

        proposal.creator = msg.sender;
        proposal.oldCustodians =  _custodians;
        proposal.newCustodians = newCustodians;
        proposal.votesFor = 1;
        proposal.votesAgainst = 0;
        proposal.votesTotal = 1;
        proposal.votesNeeded = votesNeeded;
        proposal.start = uint32(now);
        proposal.end = uint32(now + 60 * 60 * 24 * 3); 

        _proposals.push(proposal);

        _votes[uint32(_proposals.length - 1)][msg.sender] = true;

        if (_proposals[uint32(_proposals.length - 1)].votesFor == _proposals[uint32(_proposals.length - 1)].votesNeeded) {
            setNewCustodians(uint32(_proposals.length - 1));
        }

        deleteExpired();

    }

    function vote(uint32 currentProposalIndex, bool value) external override {
        require(msg.sender != address(0), Errors.INVALID_CALLER);
        require(_proposals[currentProposalIndex].oldCustodians.exists(msg.sender), Errors.INVALID_CALLER);
        require(msg.value >= Fees.PROCESS, Errors.INVALID_VALUE);
        require (now < _proposals[currentProposalIndex].end, Errors.PROPOSAL_VOTING_HAS_ENDED);

        _votes[currentProposalIndex].add(msg.sender, value);

        if (value) {
            _proposals[currentProposalIndex].votesFor++;
        } else {
            _proposals[currentProposalIndex].votesAgainst++;
        }

        _proposals[currentProposalIndex].votesTotal++;
        
        if (_proposals[currentProposalIndex].votesFor == _proposals[currentProposalIndex].votesNeeded) {
            setNewCustodians(currentProposalIndex);
        } else if (_proposals[currentProposalIndex].votesAgainst == _proposals[currentProposalIndex].votesNeeded) {
            delete _votes[currentProposalIndex];
           _proposals[currentProposalIndex] = _proposals[_proposals.length - 1];
           _proposals.pop();
        }
        
        deleteExpired();
       
    }

    function deleteExpired() private {
        for (uint i = 0; i < _proposals.length; i++) {
            if (now > _proposals[i].end) {
                _proposals[i] = _proposals[_proposals.length - 1];
                _proposals.pop();
            }
        }
    }

    function setNewCustodians(uint32 currentProposalIndex) private {
       require(_proposals[currentProposalIndex].votesFor == _proposals[currentProposalIndex].votesNeeded, Errors.INVALID_VOTES);
       
        delete _custodians;
        _custodians = _proposals[currentProposalIndex].newCustodians;
        _proposals[currentProposalIndex] = _proposals[_proposals.length - 1];
        _proposals.pop();
        delete _votes[currentProposalIndex];

    }

    function getProposals() external override returns (ProposalInfo[]) {
        return _proposals;
    }

    function getVotes() external override returns (mapping(uint32 => mapping(address => bool))) {
        return _votes;
    }
}
