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

import "./interfaces/ILLCService.sol";
import "./interfaces/IMultisig.sol";

import "./Fees.sol";

contract LLCAdminDebot is Debot, Upgradable {
    address _addrMultisig;
    address _addrLLCService;
    address _addrAdmin;
    address _feeReciever;
    uint128 _staticDeployFee;
    uint128 _distributionFee;
    uint128 _currentServiceBalance; 

    bool _inited = false;

    function init(
        address addrLLCService
    ) public {
        require(_inited == false);
        tvm.accept();
        _addrLLCService = addrLLCService;
        _inited = true;
    }

    function getDebotInfo() public functionID(0xDEB) override view returns (
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon)
    {
        name = "TeamDAO Admin";
        version = "0.1.0";
        publisher = "RSquad";
        key = "";
        author = "RSquad";
        support = address.makeAddrStd(0, 0);
        hello = "Hello, I'm TeamDAO Admin Debot.";
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

    function start() public override {
        UserInfo.getAccount(tvm.functionId(attachMultisig));
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
        _staticDeployFee =  staticDeployFee;
        _addrAdmin = addrAdmin;
        _feeReciever = feeReciever;
        _currentServiceBalance = currentBalance;
        _distributionFee = distributionFee;
        mainMenu();

    }

    function mainMenu() public {  
        if (_addrAdmin == _addrMultisig) {
            Terminal.print(0, format("Current deploy fee — {} TON Crystals", _staticDeployFee));
            Terminal.print(0, format("Current distribution fee — {}.{}%", _distributionFee * 100 / 1000, _distributionFee * 100 % 1000));
            Terminal.print(0, format("Current fee reciever — {}", _feeReciever));
            Terminal.print(0, format("Current fee amount  — {}.{} TON Crystals", _currentServiceBalance / 1 ton, _currentServiceBalance % 1 ton));
            MenuItem[] items;
            items.push(MenuItem("Set deploy fee", "", tvm.functionId(addStaticDeployFee)));
            items.push(MenuItem("Set distribution fee", "", tvm.functionId(addDistributionFee)));
            items.push(MenuItem("Set fee reciever", "", tvm.functionId(addFeeReciever)));
            items.push(MenuItem("Transfer fees", "", tvm.functionId(amountConfirm)));

            Menu.select("What can I do for you?", "", items);
        } else {
                Terminal.print(0, "You are not an admin.");
            }
    }

    function addStaticDeployFee(uint index) public { index;
        Terminal.print(0, format("Current deploy fee — {} TON Crystals", _staticDeployFee));
        AmountInput.get(
            tvm.functionId(saveStaticDeployFee),
                "Enter deploy fee:",
                0, 1, 1000);
    }

    function saveStaticDeployFee(uint128 value) public {
        TvmCell payload = tvm.encodeBody(
            ILLCService.setStaticDeployFee,
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
                callbackId: 0,
                onErrorId: tvm.functionId(onError)
            }(_addrLLCService, Fees.PROCESS_SM, true, 3, payload);
            Terminal.print(0, "Fee successfully added!");
            Terminal.print(0, format("New deploy fee — {} TON Crystals", value));
            getExt();
    }

    function addDistributionFee(uint index) public { index;
            Terminal.print(0, format("Current distribution fee — {}.{}%", _distributionFee * 100 / 1000, _distributionFee * 100 % 1000));
            Terminal.print (0, "WARNING: Fees is calculated from 1000% to 100%. Enter carefully.");
        AmountInput.get(
            tvm.functionId(saveDistributionFee),
                "Enter distribution fee (%):",
                0, 1, 1000);
    }

    function saveDistributionFee(uint128 value) public {
        TvmCell payload = tvm.encodeBody(
            ILLCService.setDistributionFee,
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
                callbackId: 0,
                onErrorId: tvm.functionId(onError)
            }(_addrLLCService, Fees.PROCESS_SM, true, 3, payload);
            Terminal.print(0, "Fee successfully added!");

            Terminal.print(0, format("New distribution fee — {}.{}%", value / 10, value % 10));
            getExt();
    }

    function addFeeReciever(uint index) public { index;
        Terminal.print(0, format("Current fee reciever — {}", _feeReciever));
        AddressInput.get(tvm.functionId(saveFeeReciever), "Enter new fee reciever address:");
    }

    function saveFeeReciever(address value) public {
        TvmCell payload = tvm.encodeBody(
            ILLCService.setFeeReciever,
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
                callbackId: 0,
                onErrorId: tvm.functionId(onError)
            }(_addrLLCService, Fees.PROCESS_SM, true, 3, payload);
            Terminal.print(0, "Fee reciever successfully added!");
            Terminal.print(0, format("New fee reciver — {}", value));
            getExt();
    }

    function amountConfirm(uint index) public { index;
        Terminal.print(0, format("Current fee amount  — {}.{} TON Crystals", _currentServiceBalance / 1 ton, _currentServiceBalance % 1 ton));
        ConfirmInput.get(tvm.functionId(transferFees), "Transer fees to reciever?");
    }

    function transferFees(bool value) public {
        if (value) {
            TvmCell payload = tvm.encodeBody(
                    ILLCService.transferFees
            );
            optional(uint256) none;
            IMultisig(_addrMultisig).sendTransaction{
                    abiVer: 2,
                    extMsg: true,
                    sign: true,
                    pubkey: none,
                    time: 0,
                    expire: 0,
                    callbackId: 0,
                    onErrorId: tvm.functionId(onError)
                }(_addrLLCService, Fees.PROCESS_SM, true, 3, payload);
            Terminal.print(0, "Fees successfully transfered to reciever!");
            getExt();
            
        } else {
            Terminal.print(0, "Transfer was cancelled.");
            getExt();
        }
        
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
        getExt();
    }

    function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }

    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Sdk error {}. Exit code {}.", sdkError, exitCode));
        mainMenu();
    }

}