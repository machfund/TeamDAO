pragma ton-solidity >= 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "./consorcium-interfaces/Debot.sol";
import "./consorcium-interfaces/Sdk.sol";
import "./consorcium-interfaces/AddressInput.sol";
import "./consorcium-interfaces/Terminal.sol";
import "./consorcium-interfaces/SigningBoxInput.sol";
import "./consorcium-interfaces/Menu.sol";
import "./consorcium-interfaces/Upgradable.sol";
import "./consorcium-interfaces/UserInfo.sol";
import "./consorcium-interfaces/AmountInput.sol";
import "./consorcium-interfaces/ConfirmInput.sol";

import "./interfaces/ILLCWallet.sol";
import "./interfaces/ILLCProposal.sol";
import "./interfaces/IMultisig.sol";
import "./interfaces/IInvokeDebot.sol";
import "./interfaces/IInvokeService.sol";

import "./Fees.sol";

contract LLCWalletDebot is Debot, Upgradable, IInvokeDebot{
    uint32 _totalShare;
    uint32 _totalCustodians;
    uint32 _currentProposalIndex;

    address _addrMultisig;
    address _addrLLCService;
    address _addrLLCWallet;
    address _addrCustodian;
    address _addrLLCServiceDebot;

    mapping(address => uint32)_newCustodians;

    ProposalInfo[] _proposals;

    function getDebotInfo() public functionID(0xDEB) override view returns (
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon)
    {
        name = "TeamDAO Wallet";
        version = "0.1.0";
        publisher = "RSquad";
        key = "";
        author = "RSquad";
        support = address.makeAddrStd(0, 0);
        hello = "Hello, I'm TeamDAO Wallet Debot.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = "";
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [
            Menu.ID,
            AddressInput.ID,
            SigningBoxInput.ID,
            UserInfo.ID,
            Terminal.ID,
            AmountInput.ID,
            ConfirmInput.ID
        ];
    }

    function debotEntryPoint(address addrLLCWallet, address addrMultisig, address addrLLCService, address addrLLCServiceDebot) external override {
        _addrLLCWallet = addrLLCWallet;
        _addrMultisig =  addrMultisig;
        _addrLLCService = addrLLCService;
        _addrLLCServiceDebot = addrLLCServiceDebot; 
        start();
    }

    function start() public override {
        if (_addrMultisig == address(0)) {
            UserInfo.getAccount(tvm.functionId(attachMultisig));   
        }        
        getLLCWalletInfo();
    }

    function getLLCWalletInfo() public {
        if (_addrLLCWallet == address(0)) {
            AddressInput.get(tvm.functionId(getExtLLCWallet), "Enter TeamDAO Wallet address:");
        } else {
            getExtLLCWallet(_addrLLCWallet); 
        }  
    }

    function getExtLLCWallet(address value) public {
        _addrLLCWallet = value;
        ILLCWallet(value).getExt{
            abiVer: 2,
            extMsg: true,
            sign: false,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(getExtLLCWalletCb),
            onErrorId: tvm.functionId(onError)
        }();
    }

    uint32 _currentCustodiansNumber; 

    function getExtLLCWalletCb(mapping(address => uint32) custodians) public {
        delete _currentCustodiansNumber;
        bool isCustodian;
        optional(address, uint32) oCustodian = custodians.min();
        while (oCustodian.hasValue()) {
            (address addrCustodian, uint32 shareCustodian) = oCustodian.get();
            Terminal.print(0, format("Custodian {} — {}%", addrCustodian, shareCustodian));
            if(addrCustodian == _addrMultisig) {
              isCustodian = true;
            }
            _currentCustodiansNumber++;
            oCustodian = custodians.next(addrCustodian);
        }
        if(isCustodian) {
          Terminal.print(0, "You're a custodian of this TeamDAO Wallet.");
          mainMenu(0);
        } else {
          Terminal.print(0, "You're not a custodian of this TeamDAO Wallet.");
          goToWallet();
        }
    }

    function goToWallet() public {
        IInvokeService(_addrLLCServiceDebot).serviceEntryPoint();
    }

    function mainMenu(uint32 index) public {
        delete _newCustodians;
        delete _totalShare;
        delete _totalCustodians;

        MenuItem[] items;
        if (_proposals.length < 10) {
            items.push(MenuItem("Propose new custodians", "", tvm.functionId(changeCustodians)));
        } else {
            Terminal.print(0, "You cannot create more than 10 active proposals.");
        }
        items.push(MenuItem("Show active proposals", "", tvm.functionId(getProposals)));
         items.push(MenuItem("Show wallet info", "", tvm.functionId(getLLCWalletInfo)));
        Menu.select("What can I do for you?", "", items);
        
    } 

    function changeCustodians(uint32 index) public {
        if (!_newCustodians.empty()) {
            MenuItem[] items;
            Terminal.print(0, format("Total share: {}%", _totalShare));
            Terminal.print(0, "New custodians:");
            optional(address, uint32) oCustodian = _newCustodians.min();
            while (oCustodian.hasValue()) {
                (address addrCustodian, uint32 shareCustodian) = oCustodian.get();
                Terminal.print(0, format("Custodian {} — {}%", addrCustodian, shareCustodian));
                oCustodian = _newCustodians.next(addrCustodian);
            }
            if (_totalShare < 100 && _totalCustodians < 100) {
                items.push(MenuItem("Add custodian", "", tvm.functionId(addCustodianAddress)));
            }
            items.push(MenuItem("Delete custodian", "", tvm.functionId(menuCustodians)));
            if (_totalShare == 100) {
                Terminal.print(0, format("All required custodians added, total {}%", _totalShare));
                items.push(MenuItem("Create proposal", "", tvm.functionId(checkProposalParams)));        }
            else {
                Terminal.print(0, format("You won't be able to create wallet until total share reaches 100%"));
            }
            items.push(MenuItem("Back", "", tvm.functionId(mainMenu)));
            Menu.select("What can I do for you?", "", items);
        }
        else {
            addCustodianAddress(0);
        }
    }

    function menuCustodians(uint32 index) public {
        MenuItem[] items;
        optional(address, uint32) oCustodian = _newCustodians.min();
        while (oCustodian.hasValue()) {
            (address addrCustodian, uint32 shareCustodian) = oCustodian.get();
            items.push(MenuItem(format("{}", addrCustodian), "", tvm.functionId(deleteCustodian)));
            oCustodian = _newCustodians.next(addrCustodian);
        }
        Menu.select("Choose custodian:", "", items);
    }

    function deleteCustodian(uint32 index) public {
        mapping(uint32 => address) custodians;
        optional(address, uint32) oCustodian = _newCustodians.min();
        uint32 i = 0;
        while (oCustodian.hasValue()) {
            (address addrCustodian, uint32 shareCustodian) = oCustodian.get();
            custodians[i] = addrCustodian;
            oCustodian = _newCustodians.next(addrCustodian);
            i++;
        }
        _totalShare -= _newCustodians[custodians[index]];
        delete _newCustodians[custodians[index]];
        Terminal.print(0, "Custodian removed.");
        mainMenu(0);
    }

    function addCustodianAddress(uint32 index) public {
            AddressInput.get(tvm.functionId(addCustodianShare), "Enter custodian address:");
    }

    function addCustodianShare(address value) public {
        _addrCustodian = value;
        if (_newCustodians.exists(_addrCustodian)) {
            Terminal.print(0, "Custodian already exists.");
            changeCustodians(0);
        } else {
            AmountInput.get(
                tvm.functionId(saveNewCustodian),
                "Enter custodian share:",
                0, 1, 100 - _totalShare); 
            }
        }
        
    function saveNewCustodian(uint32 value) public{
            _newCustodians[_addrCustodian] = value;
            _totalShare += value;
            _totalCustodians++;
            delete _addrCustodian;
            if (_totalShare == 100) {
                Terminal.print(0, format("All required custodians added, total {}%", _totalShare));
            }
            if (_totalCustodians == 100) {
                 Terminal.print(0, format("All possible custodians added, total {}%", _totalShare));
            }
            changeCustodians(0);
    }

    function checkProposalParams(uint32 index) public{
        optional(address, uint32) oCustodian = _newCustodians.min();
        while (oCustodian.hasValue()) {
            (address addrCustodian, uint32 shareCustodian) = oCustodian.get();
            Terminal.print(0, format("Custodian {} — {}%", addrCustodian, shareCustodian));
            oCustodian = _newCustodians.next(addrCustodian);
        } 
        if (_currentCustodiansNumber == 1) {
            Terminal.print(0, "Warning: you are the only custodian, created proposal will be applied automatically.");
        }
        ConfirmInput.get(tvm.functionId(createProposal), "Create proposal? You will lost all filled data if no.");       

    }
    

    function createProposal(bool value) public{
        if (value) {
            TvmCell payload = tvm.encodeBody(
                    ILLCProposal.createProposal,
                    _newCustodians
                );
            optional(uint256) none;
            IMultisig(_addrMultisig).sendTransaction{ 
                    abiVer: 2,
                    extMsg: true,
                    sign: true,
                    pubkey: none,
                    time: 0,
                    expire: 0,
                    callbackId: tvm.functionId(succeessCreateProposal),
                    onErrorId: tvm.functionId(onError)
                }(_addrLLCWallet, 1 ton, true, 3, payload);
        } else {
            delete _newCustodians;
            delete _totalShare;
            delete _totalCustodians;
            mainMenu(0);
        }
        
    }

    function succeessCreateProposal() public {
        Terminal.print(0, "Proposal was created.");
        delete _newCustodians;
        delete _totalShare;
        delete _totalCustodians;
        getProposals(0);
    }

    function getProposals(uint32 index) public {
        ILLCProposal(_addrLLCWallet).getProposals{
            abiVer: 2,
            extMsg: true,
            sign: false,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(getProposalsCb),
            onErrorId: tvm.functionId(onError)
        }();
    }

    function getProposalsCb(ProposalInfo[] proposals) public {
        _proposals = proposals;
        MenuItem[] items;
        for (uint i = 0; i < proposals.length; i++) {
            items.push(MenuItem(format("Proposal {}", i + 1), "", tvm.functionId(getProposalInfo)));
        }
        if(proposals.length > 0) {
            items.push(MenuItem("Back to wallets", "", tvm.functionId(mainMenu)));
            Menu.select("Proposals: ", "", items);
        } else {
            Terminal.print(0, 'No proposals are active.');
            mainMenu(0);
        }

    }

    function getProposalInfo(uint32 index) public {
            _currentProposalIndex = index;
            Terminal.print(0, format('Proposal {} - suggested change from',
                index + 1));
            mappingToString(_proposals[index].oldCustodians);
            Terminal.print (0, "to");
            mappingToString(_proposals[index].newCustodians);
            Terminal.print(0, format("Votes needed: {}, votes for: {}, votes against: {},  votes total: {}",
                _proposals[index].votesNeeded,
                _proposals[index].votesFor,
                _proposals[index].votesAgainst,
                _proposals[index].votesTotal));

            MenuItem[] items;
            items.push(MenuItem("Vote", "", tvm.functionId(checkIfVoted)));
            items.push(MenuItem("View votes", "", tvm.functionId(printVotes)));
            items.push(MenuItem("Back to Main Menu", "", tvm.functionId(mainMenu)));
            Menu.select("Actions: ", "", items);
    }

    function mappingToString(mapping(address => uint32) map) public{
                optional(address, uint32) oCustodian = map.min();
                while (oCustodian.hasValue()) {
                    (address addrCustodian, uint32 shareCustodian) = oCustodian.get();
                    Terminal.print(0, format("{}  - {}%", addrCustodian, shareCustodian));
                    oCustodian = map.next(addrCustodian);
                }
    }

    function mappingVoteToString (mapping(address => bool) map) public {
                optional(address, bool) oCustodian = map.min();
                while (oCustodian.hasValue()) {
                    (address addrCustodian, bool voteCustodian) = oCustodian.get();
                    if (voteCustodian) {
                        Terminal.print(0, format("{}  - voted for", addrCustodian));
                    } else {
                        Terminal.print(0, format("{}  - voted against", addrCustodian));
                    }
                    
                    oCustodian = map.next(addrCustodian);
                }
    }

    function checkIfVoted(uint32 index) public{
       getVotes(tvm.functionId(vote));
    }

    function printVotes(uint32 index) public {
        getVotes(tvm.functionId(votesToTerminal));
    }

    function getVotes(uint32 functionId) public{
        ILLCProposal(_addrLLCWallet).getVotes{
            abiVer: 2,
            extMsg: true,
            sign: false,
            time: 0,
            expire: 0,
            callbackId: functionId,
            onErrorId: tvm.functionId(onError)
        }();
    }

    function votesToTerminal(mapping(uint32 => mapping(address => bool)) votes) public {
        if (votes.exists(_currentProposalIndex)) {
            mappingVoteToString(votes[_currentProposalIndex]);
            getProposalInfo(_currentProposalIndex);
        } else {
            Terminal.print(0, "Voting has ended.");
           getProposalInfo(_currentProposalIndex);
        }

    }

    function vote(mapping(uint32 => mapping(address => bool)) votes) public {
        if (!votes[_currentProposalIndex].exists(_addrMultisig)) {
            ConfirmInput.get(tvm.functionId(saveVote), "Do you agree with new list of custodians?");
        } else {
            Terminal.print(0, "You have already voted in this proposal.");
            getProposalInfo(_currentProposalIndex);
        }
        
    }

    function saveVote(bool value) public{
        TvmCell payload = tvm.encodeBody(
            ILLCProposal.vote,
            _currentProposalIndex,
            value
        );
        optional(uint256) none;
        IMultisig(_addrMultisig).sendTransaction{ 
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: none,
                time: 0,
                expire: 0,
                callbackId: tvm.functionId(successVote),
                onErrorId: tvm.functionId(onError)
            }(_addrLLCWallet, Fees.PROCESS, true, 3, payload);
    }

    function successVote() public {
        Terminal.print(0, "Your vote was recorded.");
        getLLCWalletInfo();
    }

    function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }
    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Sdk error {}. Exit code {}.", sdkError, exitCode));
        getLLCWalletInfo();
    }

    function attachMultisig(address value) public {
        if(value == address(0)) {
            Terminal.print(0, 'Default Multisig is not found.');
            AddressInput.get(tvm.functionId(saveMultisig), "In order to use this DeBot you need to attach Multisig. Enter your Multisig address:");
        } else {
            saveMultisig(value);
        }
    }

    function saveMultisig(address value) public {
        _addrMultisig = value;
    }

}
