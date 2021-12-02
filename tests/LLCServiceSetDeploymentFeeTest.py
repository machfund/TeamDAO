
from os import fsdecode
import tonos_ts4.ts4 as ts4

from tonos_ts4.util import green, red, yellow

eq = ts4.eq

ts4.init("../build/", verbose=True)


keys_Multisig = ts4.make_keypair()

# Контракт вызывающий методы 
Wallet = ts4.BaseContract("Wallet", {})
# Сервис без адресса админа
LLCService = ts4.BaseContract("LLCService", {})
# Сервис с адрессом админа
LLCServiceAdmin = ts4.BaseContract("LLCService", {}, initial_data={"_addrAdmin": Wallet.address})

# Тест 1 без адреса админа
print (yellow("Call fron anoter contract of setStaticDeployFee with value 2000000000 and no admin address setted"))
Wallet.call_method(
        "sendTransaction",
    {
        "dest": LLCService.address,
        "value": 10000000000,
        "bounce": False,
        "flags": 0,
        "payload":ts4.encode_message_body(
            "LLCService", "setStaticDeployFee", {"staticDeployFee": 2000000000})
    },
    keys_Multisig[0]
)
ts4.dispatch_one_message(expect_ec=100)
# Проверяем что фии не засеччен
assert (LLCService.call_getter("getExt")==(0, 0, ts4.Address("0:0000000000000000000000000000000000000000000000000000000000000000"), 
                                          ts4.Address("0:0000000000000000000000000000000000000000000000000000000000000000"), 100000000000, 0))
print (green("Success: got error 100 - invalid caller"))

# Тест 2 с адресом админа
print (yellow("Call from anoter contract of setStaticDeployFee with value 2000000000 and admin address setted"))
Wallet.call_method(
        "sendTransaction",
    {
        "dest": LLCServiceAdmin.address,
        "value": 10000000000,
        "bounce": False,
        "flags": 0,
        "payload":ts4.encode_message_body(
            "LLCService", "setStaticDeployFee", {"staticDeployFee": 2000000000})
    },
    keys_Multisig[0]
)
ts4.dispatch_one_message()
# Проверяем засеченый фии
assert (LLCServiceAdmin.call_getter("getExt")==(2000000000, 0, Wallet.address, Wallet.address, 100000000000, 0))
print (green("Success: deploy fee setted"))

# Тест 3 с неверным валью
print (yellow("Call fron anoter contract of setStaticDeployFee with value 2000 and admin address setted"))
Wallet.call_method(
        "sendTransaction",
    {
        "dest": LLCServiceAdmin.address,
        "value": 10000000000,
        "bounce": False,
        "flags": 0,
        "payload":ts4.encode_message_body(
            "LLCService", "setStaticDeployFee", {"staticDeployFee": 2000})
    },
    keys_Multisig[0]
)
# ts4.dispatch_one_message(expect_ec=101)
ts4.dispatch_one_message()
# Проверяем что фии не засеччен
assert (LLCServiceAdmin.call_getter("getExt")==(2000000000, 0, Wallet.address, Wallet.address, 100000000000, 0))
print (green("Success: fee not setted"))

