// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISmartContract {

    event BalanceUpdated(address indexed user, uint256 newBalance);


    error InsufficientBalance(uint256 available, uint256 requested);


    function halfAnswerOfLife() external view returns (uint256);
    function myEthereumContractAddress() external view returns (address);
    function myEthereumAddress() external view returns (address);
    function PoCIsWhat() external view returns (string memory);

    function balances(address user) external view returns (uint256);


    function getHalfAnswerOfLife() external view returns (uint256);
    function getPoCIsWhat() external view returns (string memory);
    function completeHalfAnswerOfLife() external;

    function getMyBalance() external view returns (uint256);
    function addToBalance() external payable;
    function withdrawFromBalance(uint256 _amount) external;

    function hashMyMessage(string calldata _message) external pure returns (bytes32);
}
