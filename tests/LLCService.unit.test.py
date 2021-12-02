
import tonos_ts4.ts4 as ts4
from tonos_ts4.util import green, yellow

eq = ts4.eq

ts4.init("../build/", verbose=False)

keys_Multisig = ts4.make_keypair()
Wallet = ts4.BaseContract(
    "Wallet", {}
)

LLCService = ts4.BaseContract("LLCService", {}, initial_data={"_addrAdmin": Wallet.address})
LLCServiceDebot = ts4.BaseContract("LLCServiceDebot", {})

_custodians = {LLCService.address.str() : 100}

LLCService.call_method(
    "init", 
    {
        "codeLLCWallet": ts4.load_code_cell("LLCWallet")
    }
)

# метод теста
# value - отсылаемое значение
# isExternal - маркер внешнего вызова
def deployWalletTest(value, isExternal):
    if (isExternal):
        # вызываем из вне
        print (yellow("Extenal call of deployLLCWallet with value {}".format(value)))

        LLCService.call_method("deployLLCWallet", {"custodians": _custodians}, expect_ec=100)
        
        print (green("Success: got error 100 - invalid caller"))
    else:
        print (yellow("Internal call of deployLLCWallet with value {}".format(value)))
        
        if value<2000000000:
            # посылаем неверное значение
            Wallet.call_method(
                    "sendTransaction",
                {
                    "dest": LLCService.address,
                    "value": value,
                    "bounce": False,
                    "flags": 3,
                    "payload":ts4.encode_message_body(
                        "LLCService", "deployLLCWallet", {"custodians": _custodians})
                },
                    keys_Multisig[0]
                )
            ts4.dispatch_one_message(expect_ec=101)
            print (green("Success: got error 101 - invalid value"))

        else:
            # посылаем верное вэлью
            Wallet.call_method(
                    "sendTransaction",
                {
                    "dest": LLCService.address,
                    "value": value,
                    "bounce": False,
                    "flags": 3,
                    "payload":ts4.encode_message_body(
                        "LLCService", "deployLLCWallet", {"custodians": _custodians})
                },
                    keys_Multisig[0]
                )

            ts4.dispatch_messages()
            deployedWalletsCounter = LLCService.call_getter("_deployedWalletsCounter")
            # проверяем что кошелёк задеплоен
            assert deployedWalletsCounter>0
           
            print (green("Success: wallet deployed"))

# тест с внутрнним вызовом и парвильным значением
deployWalletTest(20000000000, False)
# тест с внешним вызовом
deployWalletTest(2000000000, True)
# тест с внутренним вызовом и неверным значением
deployWalletTest(0, False)


