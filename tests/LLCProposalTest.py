import tonos_ts4.ts4 as ts4
import time
from tonos_ts4.util import blue, bright_blue, cyan, green, red, yellow

eq = ts4.eq

ts4.init("../build/", verbose=False)

Wallet = ts4.BaseContract("Wallet", {})
Wallet2 = ts4.BaseContract("Wallet", {})
Wallet3 = ts4.BaseContract("Wallet", {})

LLCService = ts4.BaseContract("LLCService", {}, initial_data={"_addrAdmin": Wallet.address})

_custodians = {Wallet.address.str(): 50, Wallet2.address.str(): 50}

LLCService.call_method(
    "init", 
    {
        "codeLLCWallet": ts4.load_code_cell("LLCWallet")
    }
)
ts4.dispatch_messages()
# деплоим LLCWallet
Wallet.call_method(
                    "sendTransaction",
                {
                    "dest": LLCService.address,
                    "value": 100000000000,
                    "bounce": False,
                    "flags": 3,
                    "payload":ts4.encode_message_body(
                        "LLCService", "deployLLCWallet", {"custodians": _custodians})
                }
                )

ts4.dispatch_messages()

_deployedWalletsCounter = LLCService.call_getter("_deployedWalletsCounter")

addressLLCWallet = LLCService.call_getter(
        "resolveLLCWallet", {
            "addrAuthor": LLCService.address,
            "id": _deployedWalletsCounter
        })

LLCProposal = ts4.BaseContract("LLCProposal", ctor_params=None, address=addressLLCWallet, balance=0)

_custodiansNew = {Wallet.address.str() : 34, Wallet2.address.str(): 33, Wallet3.address.str(): 33}

Wallet.call_method(
    "sendTransaction",
    {
        "dest": LLCProposal.address,
        "value": 1000000000,
        "bounce": True,
        "flags": 0,
        "payload":ts4.encode_message_body(
            "LLCProposal", "createProposal", {"newCustodians": _custodiansNew}
        )
    },
)

print(blue("Creating proposal to change custodians to 3 wallets"))
ts4.dispatch_messages()

print(yellow("Propolsals:"))
print(LLCProposal.call_getter("getProposals"))
print(yellow("Votes:"))
print(LLCProposal.call_getter("getVotes"))

Wallet2.call_method(
    "sendTransaction",
    {
        "dest": LLCProposal.address,
        "value": 10000000000,
        "bounce": False,
        "flags": 0,
        "payload":ts4.encode_message_body
        (
            "LLCProposal", "vote",
            {
                "currentProposalIndex": 0,
                "currentUser": Wallet2.address,
                "value": True
            }
        )
    }
)

print(blue("Dispaching vote for"))
ts4.dispatch_messages()

print(yellow("Votes:"))
votes = LLCProposal.call_getter("getVotes") 
print(votes)
assert (votes == {})
print(green("Succsess. No votes."))
print(yellow("Propolsals:"))
props = LLCProposal.call_getter("getProposals")
print(props)
assert (props == [])
print(green("Succsess. No active proposals."))

print(yellow("Custodians:"))
cust = LLCProposal.call_getter("_custodians")
print(cust)
comparator = {Wallet.address: 34, Wallet2.address: 33, Wallet3.address: 33}
assert(cust == comparator)
print(green("Succsess. Custodians changed."))



Wallet.call_method(
    "sendTransaction",
    {
        "dest": LLCProposal.address,
        "value": 1000000000,
        "bounce": True,
        "flags": 0,
        "payload":ts4.encode_message_body(
            "LLCProposal", "createProposal", {"newCustodians": _custodians}
        )
    },
)

print(blue("Creating proposal to change back to 2 wallets"))
ts4.dispatch_messages()

print(yellow("Propolsals:"))
print(LLCProposal.call_getter("getProposals"))
print(yellow("Votes:"))
print(LLCProposal.call_getter("getVotes"))

Wallet2.call_method(
    "sendTransaction",
    {
        "dest": LLCProposal.address,
        "value": 10000000000,
        "bounce": False,
        "flags": 0,
        "payload":ts4.encode_message_body
        (
            "LLCProposal", "vote",
            {
                "currentProposalIndex": 0,
                "currentUser": Wallet2.address,
                "value": False
            }
        )
    }
)

print(blue("Dispaching vote aginst from Wallet 2"))
ts4.dispatch_messages()

print(yellow("Votes:"))
votes = LLCProposal.call_getter("getVotes") 
print(votes)
assert (votes != {})
print(green("Succsess. 2 votes."))
print(yellow("Propolsals:"))
props = LLCProposal.call_getter("getProposals")
print(props)
assert (props != [])
print(green("Succsess. 1 active proposal."))


Wallet3.call_method(
    "sendTransaction",
    {
        "dest": LLCProposal.address,
        "value": 10000000000,
        "bounce": False,
        "flags": 0,
        "payload":ts4.encode_message_body
        (
            "LLCProposal", "vote",
            {
                "currentProposalIndex": 0,
                "currentUser": Wallet2.address,
                "value": False
            }
        )
    }
)

print(blue("Dispaching vote against from Wallet 3"))
ts4.dispatch_messages()

print(yellow("Votes:"))
votes = LLCProposal.call_getter("getVotes") 
print(votes)
assert (votes == {})
print(green("Succsess. No votes."))
print(yellow("Propolsals:"))
props = LLCProposal.call_getter("getProposals")
print(props)
assert (props == [])
print(green("Succsess. No active proposals."))

print(yellow("Custodians:"))
cust = LLCProposal.call_getter("_custodians")
print(cust)
comparator = {Wallet.address: 34, Wallet2.address: 33, Wallet3.address: 33}
assert(cust == comparator)
print(green("Succsess. Custodians didn't changed."))

print(red("Proposal delete expired test"))
Wallet.call_method(
    "sendTransaction",
    {
        "dest": LLCProposal.address,
        "value": 1000000000,
        "bounce": True,
        "flags": 0,
        "payload":ts4.encode_message_body(
            "LLCProposal", "createProposal", {"newCustodians": _custodians}
        )
    },
)

ts4.dispatch_messages()
print(yellow("Propolsals:"))
props = LLCProposal.call_getter("getProposals")
assert(props != [])
print(props)

now = int(time.time())
DAY = 86400
ts4.core.set_now(now + 4 * DAY)
print(yellow("Setting time forward 4 days"))

Wallet.call_method(
    "sendTransaction",
    {
        "dest": LLCProposal.address,
        "value": 1000000000,
        "bounce": True,
        "flags": 0,
        "payload":ts4.encode_message_body(
            "LLCProposal", "createProposal", {"newCustodians": _custodiansNew}
        )
    },
)

ts4.dispatch_messages()
print(yellow("Propolsals:"))
props = LLCProposal.call_getter("getProposals")
print(props)
assert(props.__len__()==1)
print(green("Succsess expired proposal deleted"))
