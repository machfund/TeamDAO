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
import "./consorcium-interfaces/QRCode.sol";

import "./interfaces/ILLCService.sol";
import "./interfaces/ILLCWalletResolver.sol";
import "./interfaces/IMultisig.sol";
import "./interfaces/IInvokeDebot.sol";
import "./interfaces/IInvokeService.sol";

import "./Fees.sol";

contract LLCServiceDebot is Debot, Upgradable, IInvokeService {
    address _addrMultisig;

    bool _inited = false;

    address _addrLLCService;
    address _addrLLCWalletDebot;

    mapping(address => uint32) _custodians;
    uint32 _deployedWalletsCounter;

    uint128 _staticDeployFee;
    uint128 _distributionFee;
    address _addrCustodian;

    uint32 _totalShare;
    uint32 _totalCustodians;
    uint128 _deployedWalletsCounterBefore;

    function init(
        address addrLLCService,
        address addrLLCWalletDebot
    ) public {
        require(_inited == false);
        tvm.accept();
        _addrLLCService = addrLLCService;
        _addrLLCWalletDebot =  addrLLCWalletDebot;
        _inited = true;
    }

    function serviceEntryPoint() external override {
        start();
    }

    function getDebotInfo() public functionID(0xDEB) override view returns (
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon)
    {
        name = "TeamDAO Multisig";
        version = "0.1.0";
        publisher = "RSquad";
        key = "";
        author = "RSquad";
        support = address.makeAddrStd(0, 0);
        hello = "Hello, I'm TeamDAO Multisig Debot.";
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
            ConfirmInput.ID,
            QRCode.ID
        ];
    }

    function start() public override {
        getExt();
    }

    function getExt() public {
         ILLCService(_addrLLCService).getExt{
            abiVer: 2,
            extMsg: true,
            sign: false,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(getExtLLCServiceCb),
            onErrorId: tvm.functionId(onError)
        }();
    }

    function getExtLLCServiceCb(uint128 staticDeployFee, uint32 deployedWalletsCounter, address addrAdmin, address feeReciever, uint128 currentBalance, uint128 distributionFee) public {
        _staticDeployFee = staticDeployFee;
        _deployedWalletsCounter = deployedWalletsCounter;
        _deployedWalletsCounterBefore = _deployedWalletsCounter; 
        _distributionFee = distributionFee;
        UserInfo.getAccount(tvm.functionId(attachMultisig));
    }

    function mainMenu() public {
        delete _custodians;
        delete _addrCustodian;
        delete _totalShare;
        delete _totalCustodians;

        MenuItem[] items;
        items.push(MenuItem("Create TeamDAO Wallet", "", tvm.functionId(createLLCWallet)));
        items.push(MenuItem("Go to TeamDAO Wallet", "", tvm.functionId(withoutCreation)));
        Menu.select("What can I do for you?", "", items);
    }

    function createLLCWallet(uint index) public { index;
        optional(address, uint32) oCustodian = _custodians.min();
        while (oCustodian.hasValue()) {
            (address addrCustodian, uint32 shareCustodian) = oCustodian.get();
            Terminal.print(0, format("Custodian {} — {}%", addrCustodian, shareCustodian));
            oCustodian = _custodians.next(addrCustodian);
        }

        MenuItem[] items;
        if(_totalShare < 100 && _totalCustodians < 100) {
            items.push(MenuItem("Add custodian", "", tvm.functionId(addCustodianAddress)));
        }
        if(!_custodians.empty()) {
            Terminal.print(0, format("Total share: {}%", _totalShare));
            items.push(MenuItem("Delete custodian", "", tvm.functionId(menuCustodians)));
        if (_totalShare == 100) {
            Terminal.print(0, format("All required custodians added, total {}%", _totalShare));
            items.push(MenuItem("Create TeamDAO Wallet", "", tvm.functionId(checkLLCMultisigParams)));
        }
        else {
            Terminal.print(0, format("You won't be able to create wallet until total share reaches 100%."));
        }
        }
        items.push(MenuItem("Back to main menu", "", tvm.functionId(mainMenu)));

        Menu.select("What can I do for you?", "", items);
    }

    function addCustodianAddress(uint index) public { index;
        AddressInput.get(tvm.functionId(saveCustodianAddress), "Enter custodian address:");
    }

    function saveCustodianAddress(address value) public {
        _addrCustodian = value;
        if (_custodians.exists(_addrCustodian)) {
            Terminal.print(0, "Custodian is already in the list.");
            createLLCWallet(0);
            }
        else {
             AmountInput.get(
                tvm.functionId(saveCustodianShare),
                "Enter custodian share:",
                0, 1, 100 - _totalShare);
        }
    }

    function saveCustodianShare(uint32 value) public {
             _custodians[_addrCustodian] = value;
            delete _addrCustodian;
            _totalShare += value;
            _totalCustodians++;
            if (_totalShare == 100) {
                Terminal.print(0, format("All required custodians added, total {}%", _totalShare));
            }
            if (_totalCustodians == 100) {
                Terminal.print(0, format("All possible custodians added, total {}%", _totalShare));
            }
            createLLCWallet(0);

    }

    function chooseDeleteCustodian(uint32 index) public { index;
        mapping(uint32 => address) custodians;
        optional(address, uint32) oCustodian = _custodians.min();
        uint32 i = 0;
        while (oCustodian.hasValue()) {
            (address addrCustodian, uint32 shareCustodian) = oCustodian.get();
            custodians[i] = addrCustodian;
            oCustodian = _custodians.next(addrCustodian);
            i++;
        }
        deleteCustodian(custodians[index]);
    }

    function menuCustodians(uint32 index) public {
        MenuItem[] items;
        optional(address, uint32) oCustodian = _custodians.min();
        while (oCustodian.hasValue()) {
            (address addrCustodian, uint32 shareCustodian) = oCustodian.get();
            items.push(MenuItem(format("{}", addrCustodian), "", tvm.functionId(chooseDeleteCustodian)));
            oCustodian = _custodians.next(addrCustodian);
        }
        items.push(MenuItem("Back to main menu", "", tvm.functionId(createLLCWallet)));
        Menu.select("Choose custodians:", "", items);
    }

    function deleteCustodian(address value) public {
        if (!_custodians.exists(value))  {
            Terminal.print(0, "Custodian is not in the list.");
            createLLCWallet(0);
            }
        else {
            _totalShare -= _custodians[value];
            delete _custodians[value];
            Terminal.print(0, "Custodian deleted.");
            createLLCWallet(0);
            }

    }
     
    function checkLLCMultisigParams(uint32 index) public { index;
        optional(address, uint32) oCustodian = _custodians.min();
        while (oCustodian.hasValue()) {
            (address addrCustodian, uint32 shareCustodian) = oCustodian.get();
            Terminal.print(0, format("Custodian {} — {}%", addrCustodian, shareCustodian));
            oCustodian = _custodians.next(addrCustodian);
        }
        Terminal.print(0, format("Deploy fee — {} TON Crystals", _staticDeployFee));
        ConfirmInput.get(tvm.functionId(deployLLCWallet), "Deploy TeamDAO Wallet? You will lost all filled data if no.");
    }

   

    function deployLLCWallet(bool value) public{
        if(value) {
            TvmCell payload = tvm.encodeBody(
                ILLCService.deployLLCWallet,
                _custodians
            );
            optional(uint256) none;
            if (_custodians.empty()) Terminal.print (0, "empty");
            IMultisig(_addrMultisig).sendTransaction{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: none,
                time: 0,
                expire: 0,
                callbackId: tvm.functionId(getExt1),
                onErrorId: tvm.functionId(onError)
            }(_addrLLCService, Fees.DEPLOY + Fees.PROCESS + _staticDeployFee * 1 ton, true, 3, payload);
        } else {
            delete _custodians;
            delete _totalShare;
            delete _totalCustodians;
            mainMenu();
        }
    }

    function successDeployLLCWallet() public {
        if (_deployedWalletsCounter > _deployedWalletsCounterBefore) {
            Terminal.print(0, "Operation successfull!");
            resolveLLCWallet();
        } else {
            Terminal.print(tvm.functionId(mainMenu), "Deploying failed.");
        }
    }

    function getExt1() public {
         ILLCService(_addrLLCService).getExt{
            abiVer: 2,
            extMsg: true,
            sign: false,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(getExtLLCServiceCb1),
            onErrorId: tvm.functionId(onError)
        }();
    }

    function getExtLLCServiceCb1(uint128 staticDeployFee, uint32 deployedWalletsCounter, address addrAdmin, address feeReciever, uint128 currentBalance, uint128 distributionFee) public {
        _deployedWalletsCounter = deployedWalletsCounter;
        successDeployLLCWallet();
    }

    function resolveLLCWallet() public {
        ILLCWalletResolver(_addrLLCService).resolveLLCWallet{
            abiVer: 2,
            extMsg: true,
            sign: false,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(resolveLLCWalletCb),
            onErrorId: tvm.functionId(onError)
        }(_addrLLCService, _deployedWalletsCounter);
    }

    function resolveLLCWalletCb(address addrLLCWallet) public {
        Terminal.print(0, format("Distribution fee — {}.{}%", _distributionFee / 10, _distributionFee % 10));
        Terminal.print(0, "Your TeamDAO Wallet is ");
        Terminal.print(0, format("{}", addrLLCWallet));
        createJson (addrLLCWallet);
    }

    function createJson(address value) public {
        string json = format("{}",
            value
        );
        QRCode.draw(0, "Your TeamDAO Wallet QR. Scan it.", json);
        goToWallet(value);
    }

    function setDrawResult(QRStatus result) public {
        if (result != QRStatus.Success) {
            Terminal.print(tvm.functionId(mainMenu), "Failed to draw QRCode.");
        } 
    }

    function withoutCreation(uint32 index) public {
        goToWallet(address(0));
    }
    
    function goToWallet(address addrLLCWallet) public {
        IInvokeDebot(_addrLLCWalletDebot).debotEntryPoint(
            addrLLCWallet,
            _addrMultisig,
            _addrLLCService,
            address(this)
        );
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
        mainMenu();
    }

    function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }

    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Sdk error {}. Exit code {}.", sdkError, exitCode));
        mainMenu();
    }
}
