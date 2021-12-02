pragma ton-solidity >= 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import "./resolvers/LLCWalletResolver.sol";

import "./interfaces/ILLCService.sol";

import "./LLCProposal.sol";

import "./Errors.sol";
import "./Fees.sol";

contract LLCService is ILLCService, LLCWalletResolver {
    address static _addrAdmin;
    uint128 _staticDeployFee;
    uint128 _distributionFee;
    address _feeReciever = _addrAdmin;

    uint32 _deployedWalletsCounter;
    uint16 _version = 1;

    bool _inited = false;

    function init(
        TvmCell codeLLCWallet
    ) public {
        require(!codeLLCWallet.toSlice().empty(), Errors.INVALID_ARGUMENTS);
        require(_inited == false, Errors.CONTRACT_INITED);
        tvm.accept();
        _codeLLCWallet = codeLLCWallet;
        _inited = true;
    }

    function setStaticDeployFee(uint128 staticDeployFee) external override {
        require(_addrAdmin == msg.sender, Errors.INVALID_CALLER);
        require(msg.value >= Fees.PROCESS_SM, Errors.INVALID_VALUE);
        _staticDeployFee = staticDeployFee;
        msg.sender.transfer(0, false, 64);
    }

    function setDistributionFee(uint128 distributionFee) external override {
        require(_addrAdmin == msg.sender, Errors.INVALID_CALLER);
        require(msg.value >= Fees.PROCESS_SM, Errors.INVALID_VALUE);
        _distributionFee = distributionFee;
        msg.sender.transfer(0, false, 64);
    }

    function setFeeReciever(address feeReciever) external override {
        require(_addrAdmin == msg.sender, Errors.INVALID_CALLER);
        require(msg.value >= Fees.PROCESS_SM, Errors.INVALID_VALUE);
        _feeReciever = feeReciever;
        msg.sender.transfer(0, false, 64);         
    }

    function deployLLCWallet(
        mapping(address => uint32) custodians
    ) external override {
        require(msg.sender != address(0), Errors.INVALID_CALLER);
        require(
            msg.value >= Fees.DEPLOY + Fees.PROCESS_SM + _staticDeployFee * 1 ton,
            Errors.INVALID_VALUE
        );

        tvm.rawReserve(_staticDeployFee * 1 ton, 4);

        TvmCell state = _buildLLCWalletState(address(this), _deployedWalletsCounter + 1);
        new LLCWallet
            {stateInit: state, value: Fees.DEPLOY}
            (custodians, _distributionFee);
        
        _deployedWalletsCounter++;
        
        msg.sender.transfer(0, true, 128);
    
    }

    function transferFees() external override {
        require(_addrAdmin == msg.sender, Errors.INVALID_CALLER);
        _feeReciever.transfer(0, true, 128);
    }

    function getExt() external override returns (
        uint128 staticDeployFee,
        uint32 deployedWalletsCounter,
        address addrAdmin,
        address feeReciever,
        uint128 currentBalance,
        uint128 distributionFee
    ) {
        staticDeployFee = _staticDeployFee;
        deployedWalletsCounter = _deployedWalletsCounter;
        addrAdmin = _addrAdmin;
        feeReciever = _feeReciever;
        currentBalance = address(this).balance;
        distributionFee = _distributionFee;
    }


}
