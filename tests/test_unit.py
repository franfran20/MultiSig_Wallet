import pytest
from brownie import accounts, network, exceptions
from web3 import Web3
from scripts.helpful_scripts import OWNERS, REQUIREDCONFIRMATIONS, get_account
from scripts.deploy import deploy

# amount of ether to send for testing
one_ether = Web3.toWei(1, "ether")


def test_submit_transaction():
    if network.show_active() != "development":
        pytest.skip("Only Local Tests are supported")

    multisig = deploy()
    # first account submit a transaction
    print("Submitting transaction...")
    tx_submit = multisig.submitTransaction(
        accounts[6].address, one_ether, {"from": accounts[1]}
    )
    print("Transaction submitted!")
    tx_submit.wait(1)

    # checking if the address and value match the set address and value when submiting a tx
    assert multisig.transactions(0)[0] == accounts[6].address
    assert multisig.transactions(0)[1] == one_ether


def test_confirm_transaction():
    multisig = deploy()
    # first account submit a transaction
    print("Submitting transaction...")
    tx_submit = multisig.submitTransaction(
        accounts[6].address, one_ether, {"from": accounts[1]}
    )
    tx_submit.wait(1)

    # confirm transaction with account 1 2 3
    print("Confirming transaction...")
    multisig.confirmTransaction(0, {"from": accounts[1]})
    multisig.confirmTransaction(0, {"from": accounts[2]})
    multisig.confirmTransaction(0, {"from": accounts[3]})

    # only one confirmation at a time
    with pytest.raises(exceptions.VirtualMachineError):
        multisig.confirmTransaction(0, {"from": accounts[3]})

    # can only confirm tx that exists
    with pytest.raises(exceptions.VirtualMachineError):
        multisig.confirmTransaction(1, {"from": accounts[3]})

    # only owner can confirm tx
    with pytest.raises(exceptions.VirtualMachineError):
        multisig.confirmTransaction(0, {"from": accounts[6]})

    # early test
    # making sure we cant confirm an executed transaction
    print("Executing..")
    tx_execute = multisig.executeTransaction(0, {"from": accounts[4]})
    tx_execute.wait(1)
    with pytest.raises(exceptions.VirtualMachineError):
        multisig.confirmTransaction(0, {"from": accounts[6]})

    # three confirmations
    assert multisig.transactions(0)[3] == 3


def test_revoke_transaction():
    multisig = deploy()
    # first account submit a transaction
    print("Submitting transaction...")
    multisig.submitTransaction(accounts[6].address, one_ether, {"from": accounts[1]})

    # confirm transaction with account 1 2 3
    print("Confirming transaction...")
    multisig.confirmTransaction(0, {"from": accounts[1]})
    multisig.confirmTransaction(0, {"from": accounts[2]})
    multisig.confirmTransaction(0, {"from": accounts[3]})

    # account 3 revoking transaction and re-confirming
    tx_revoke = multisig.revokeTransaction(0, {"from": accounts[3]})
    tx_revoke.wait(1)
    # expecting only two confirmations since we revoked one
    assert multisig.transactions(0)[3] == 2
    multisig.confirmTransaction(0, {"from": accounts[3]})
    assert multisig.transactions(0)[3] == 3
