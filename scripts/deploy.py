from brownie import accounts, MultiSigWallet
from scripts.helpful_scripts import OWNERS, get_account, REQUIREDCONFIRMATIONS


def deploy():
    acct = get_account()
    multisig_wallet = MultiSigWallet.deploy(
        OWNERS, REQUIREDCONFIRMATIONS, {"from": acct}
    )
    return multisig_wallet


def main():
    deploy()
