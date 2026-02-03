// SPDX-License-Identifier: MIT
import "./interfaces/ISmartContract.sol";
pragma solidity ^0.8.20;

contract SmartContract is ISmartContract {
    uint256 public halfAnswerOfLife = 21;
    address public myEthereumContractAddress = address(this);
    address public myEthereumAddress = msg.sender;
    string public PoCIsWhat = "PoC is good, PoC is life.";
    bool internal _areYouABadPerson = false;
    int256 private _youAreACheater = -42;

    bytes32 public whoIsTheBest;
    mapping(string => uint256) public myGrades;
    string[5] public myPhoneNumber;

    enum roleEnum { STUDENT, TEACHER }
    struct informations {
        string firstName;
        string lastName;
        uint8 age;
        string city;
        roleEnum role;
    }
    informations public myInformations;

    address private owner;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        owner = msg.sender;
        whoIsTheBest = keccak256(abi.encodePacked("You"));

        myPhoneNumber = ["01","23","45","67","89"];

        myInformations = informations({
            firstName: "Alice",
            lastName: "Blockchain",
            age: 25,
            city: "Ethereum City",
            role: roleEnum.STUDENT
        });

        myGrades["Solidity"] = 100;
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }


    function getHalfAnswerOfLife() public view returns (uint256) {
        return halfAnswerOfLife;
    }

    function _getMyEthereumContractAddress() internal view returns (address) {
        return myEthereumContractAddress;
    }

    function getPoCIsWhat() external view returns (string memory) {
        return PoCIsWhat;
    }

    function _setAreYouABadPerson(bool _value) internal {
        _areYouABadPerson = _value;
    }

    function completeHalfAnswerOfLife() public onlyOwner {
        halfAnswerOfLife += 21;
    }

    function hashMyMessage(string calldata _message) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message));
    }



    mapping(address => uint256) public balances;

    function getMyBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function addToBalance() public payable {
        balances[msg.sender] += msg.value;
        emit BalanceUpdated(msg.sender, balances[msg.sender]);
    }

    function withdrawFromBalance(uint256 _amount) public {
        if (balances[msg.sender] < _amount) {
            revert InsufficientBalance(balances[msg.sender], _amount);
        }

        balances[msg.sender] -= _amount;
        emit BalanceUpdated(msg.sender, balances[msg.sender]);

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
    }
}
