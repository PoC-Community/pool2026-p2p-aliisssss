// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SmartContract.sol";

contract SmartContractHelper is SmartContract {
    function areYouABadPerson() external view returns (bool) {
        return _areYouABadPerson;
    }
}
contract SmartContractTest is Test {
    SmartContract smartContract;
    SmartContractHelper helper;
    

    function setUp() public {
        smartContract = new SmartContract();
        helper = new SmartContractHelper();
    }


    function testHalfAnswerOfLife() public {
        assertEq(smartContract.getHalfAnswerOfLife(), 21);
    }

    function testinternalvariable() public {
        bool value = helper.areYouABadPerson();
        assertEq(value, false);
    }
    function testStructValues() public {
        (
            string memory firstName,
            string memory lastName,
            uint8 age,
            string memory city,
            SmartContract.roleEnum role
        ) = smartContract.myInformations();

        assertEq(firstName, "Alice");
        assertEq(lastName, "Blockchain");
        assertEq(age, 25);
        assertEq(city, "Ethereum City");
        assertEq(uint(role), uint(SmartContract.roleEnum.STUDENT));
    }
}
