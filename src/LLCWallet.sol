pragma ton-solidity >= 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/ILLCWallet.sol';
import "./LLCProposal.sol";

import "./Errors.sol";
import "./Fees.sol";

contract LLCWallet is ILLCWallet, LLCProposal {
    uint32 static _id;
    address _addrAuthor;

    uint128 _distributionFee;

    uint16 _version = 1;

    bool _inited = false;

        function init(
        mapping(address => uint32) custodians
    ) private {
     uint32 totalShare;
        optional(address, uint32) oCustodian = custodians.min();
        while (oCustodian.hasValue()) {
            (address addrCustodian, uint32 shareCustodian) = oCustodian.get();
            totalShare += shareCustodian;
            oCustodian = custodians.next(addrCustodian);
        }
        require(totalShare == 100, Errors.INVALID_VALUE);
        _inited = true;
    }

    constructor(mapping(address => uint32) custodians, uint128 distributionFee) public {
        optional(TvmCell) oSalt = tvm.codeSalt(tvm.code());
        require(oSalt.hasValue());
        (address addrAuthor) = oSalt.get().toSlice().decode(address);
        require(addrAuthor == msg.sender, Errors.INVALID_CALLER);
        require(addrAuthor != address(0), Errors.INVALID_CALLER);
        init(custodians);
        if (_inited) {
            _addrAuthor = addrAuthor;
            _custodians = custodians;
            _distributionFee = distributionFee;
        }
    }

    function getExt() external override returns (
        mapping(address => uint32) custodians
    ) {
        custodians = _custodians;
    }

    function distributeRecieved() private inline {
        uint128 fee = msg.value * _distributionFee / 1000;
        optional(address, uint32) oCustodian = _custodians.min();
        while (oCustodian.hasValue()) {
            (address addrCustodian, uint32 shareCustodian) = oCustodian.get();
            uint128 custodianPart = (msg.value - fee) * shareCustodian / 100;
            addrCustodian.transfer(custodianPart, false, 3);
            oCustodian = _custodians.next(addrCustodian);
        }
        if (_distributionFee > 0) _addrAuthor.transfer(fee, false, 3);
    }

    fallback () external {

    }

    receive () external {
        distributeRecieved();
    }
}
