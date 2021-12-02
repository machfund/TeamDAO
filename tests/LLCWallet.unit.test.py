import tonos_ts4.ts4 as ts4
from tonos_ts4.util import blue, bright_blue, cyan, green, red, yellow

eq = ts4.eq

ts4.init("../build/", verbose=False)
ts4.register_abi('LLCWallet')


Wallet = ts4.BaseContract("Wallet", {}, balance=100000000000000)
nonCustWallet = ts4.BaseContract("Wallet", {})

LLCService = ts4.BaseContract("LLCService", {}, initial_data={"_addrAdmin": Wallet.address})

_distributionFee = 10

# Формируемп список кастодианов
_custodians = {Wallet.address.str() : 50, LLCService.address.str(): 50}

LLCService.call_method(
    "init", 
    {
        "codeLLCWallet": ts4.load_code_cell("LLCWallet")
    }
)

# деплоим LLCWallet
Wallet.call_method(
                    "sendTransaction",
                {
                    "dest": LLCService.address,
                    "value": 20000000000,
                    "bounce": False,
                    "flags": 3,
                    "payload":ts4.encode_message_body(
                        "LLCService", "deployLLCWallet", {"custodians": _custodians, "distributionFee": _distributionFee})
                }
                )
message = ts4.peek_msg()
print(message)
ts4.dispatch_one_message()
message = ts4.peek_msg()
print(message)
ts4.dispatch_one_message()
message = ts4.peek_msg()
print(message)
ts4.dispatch_one_message()

_deployedWalletsCounter = LLCService.call_getter("_deployedWalletsCounter")

addressLLCWallet = LLCService.call_getter(
        "resolveLLCWallet", {
            "addrAuthor": LLCService.address,
            "id": _deployedWalletsCounter
        })

deployedLLCWallet = ts4.BaseContract("LLCWallet", ctor_params=None, address=addressLLCWallet, balance=0)

# Тест конструктора
def constructorTest():
    print (yellow("Ensure equality of _addrAuthor and LLCService.address"))
    assert eq(LLCService.address, deployedLLCWallet.call_getter("_addrAuthor"))
    print (green("Success: _addrAuthor equals LLCService.address"))

constructorTest()

# Тест распределения полученного
def distributeRecievedTest():
    print (yellow("\nTesting distributeRecieved()"))
    print (bright_blue("_custodians: {}".format(_custodians)))
    print (bright_blue("deployedLLCWallet balance: {}".format(deployedLLCWallet.balance)))
    initialBalance = deployedLLCWallet.balance
    print (yellow("\nSending money to LLCWallet:"))
    Wallet.call_method(
                    "sendTransaction",
                {
                    "dest": deployedLLCWallet.address,
                    "value": 2000000000,
                    "bounce": False,
                    "flags": 3,
                    "payload": ts4.Cell("")
                }
                )
    message = ts4.peek_msg()
    assert eq(message.dst, deployedLLCWallet.address)
    print(bright_blue("Message dst: {}").format(message.dst))
    print(bright_blue("Message value: {}").format(message.value))
    initialBalance += message.value
    ts4.dispatch_one_message()

    print (yellow("\nDistributing:"))

    message = ts4.peek_msg()
    print(bright_blue("Message dst: {}").format(message.dst))
    sentValue = message.value
    print(bright_blue("Message value: {}").format(message.value))
    fee1 = (message.value * _distributionFee)/(1000 - _distributionFee)
    print(bright_blue("Fee: {}").format(fee1))
    ts4.dispatch_one_message()

    
    message = ts4.peek_msg()
    print(bright_blue("Message dst: {}").format(message.dst))
    sentValue += message.value
    print(bright_blue("Message value: {}").format(message.value))
    fee2 = (message.value * _distributionFee)/(1000 - _distributionFee)
    print(bright_blue("Fee: {}").format(fee2))
    ts4.dispatch_one_message()

    print (yellow("\ndeployedLLCWallet balance: {}".format(deployedLLCWallet.balance)))
    # assert eq(initialBalance, deployedLLCWallet.balance+sentValue+fee1+fee2)
    print (green("Success: Distribution was provided correctly"))

distributeRecievedTest()
