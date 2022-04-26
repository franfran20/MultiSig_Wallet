from brownie import accounts, network
from web3 import Web3


LOCAL_BLOCKCHAIN_ENV = ["development", "ganache", "hardhat"]


def get_account(id=None, index=None):
    if network.show_active() in LOCAL_BLOCKCHAIN_ENV:
        return accounts[0]
    if id:
        return accounts.load(id)
    if index:
        return accounts[index]


# owners using accounts 1 to 5
OWNERS = [
    "0x33A4622B82D4c04a53e170c638B944ce27cffce3",
    "0x0063046686E46Dc6F15918b61AE2B121458534a5",
    "0x21b42413bA931038f35e7A5224FaDb065d297Ba3",
    "0x46C0a5326E643E4f71D3149d50B48216e174Ae84",
    "0x807c47A89F720fe4Ee9b8343c286Fc886f43191b",
]

# number of confirmations required
REQUIREDCONFIRMATIONS = 3
