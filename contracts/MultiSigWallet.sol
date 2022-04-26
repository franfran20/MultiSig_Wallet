//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract MultiSigWallet{
    //emits an event everytime our contract receives ether.
    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    //emits an event everytime a transaction is proposed.
    event SubmitTransaction(
        address indexed owner, 
        uint indexed txIndex, 
        address indexed to, 
        uint256 value
    );

    //emits events that confirms transaction, revokes transaction and executes transaction
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeTransaction(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    //the addresses of the owners
    address[] public owners;
    //num of confirmations required for a user
    uint public numConfirmationsRequired;

    //to check if an address is the owner
    mapping(address => bool) public isOwner;

    //transaction struct of what a tx should have
    struct Transaction{
        address to;
        uint value;
        bool executed;
        uint numConfirmations;
        mapping(address => bool) isConfirmed;
        mapping(address => bool) isRevoked;
    }

    //Array of transactions to keep track of each tx
    Transaction[] public transactions;


    constructor(address[] memory _owners, uint _numConfirmationsRequired) public{
        require(_owners.length > 0, "There must be at least 1 owner");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired < _owners.length, "Invalid number of confirmations for specified owners");
        
        //check if theres a repititive address 
        for(uint i = 0; i < _owners.length; i++){
            address owner = _owners[i];

            require(owner != address(0), "Invalid Owner");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        //setting the number of confirmations required
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    //modifier that checks if the owner is stored in our owners mapping
    modifier onlyOwner(){
        require(isOwner[msg.sender], "You aren't an owner");
        _;
    }

    //submits the transaction for approval
    function submitTransaction(address _to, uint256 _value) public onlyOwner{
        //sets the tx index to be equal to the length of transaction array
        //so every time we push a tx we increase the length giving it a different tx each time.
        uint txIndex = transactions.length;

        //pushin the tx
        transactions.push(Transaction({to: _to, value: _value, executed: false, numConfirmations: 0
        }));

        //emit an event for the transaction proposed.
        emit SubmitTransaction(msg.sender, txIndex, _to, _value);

    }

    //to check if the tx exist
    modifier txExists(uint _txIndex){
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    //checks if tx has been executed
    modifier notExecuted(uint _txIndex){
        require(!transactions[_txIndex].executed, "tx is already executed");
        _;
    }

    //checks if tx has been confirmed
    modifier notConfirmed(uint _txIndex){
        require(!transactions[_txIndex].isConfirmed[msg.sender], "tx confirmed already");
        _;
    }

    //checks if tx has been confirmed
    modifier notRevoked(uint _txIndex){
        require(!transactions[_txIndex].isRevoked[msg.sender], "tx revoked already");
        _;
    }

    //confirms the transaction 
    function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex){
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        transaction.isConfirmed[msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    //confirms the transaction 
    function revokeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notRevoked(_txIndex){
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.isConfirmed[msg.sender]);
        transaction.isConfirmed[msg.sender] = false;
        transaction.numConfirmations -= 1;

        emit RevokeTransaction(msg.sender, _txIndex);
    }

    //executes the transaction after confirmation
    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex){
        Transaction storage transaction = transactions[_txIndex];

        require(transaction.numConfirmations >= numConfirmationsRequired, "This transaction hasn't met the minimum number of confirmations");

        transaction.executed = true;

        address payable receipient = payable(transaction.to);
        uint256 amount = transaction.value;
        (bool success, ) = receipient.call{value: amount}("");
        require(success, "Tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    //fallback function 
    receive() external payable{
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
}