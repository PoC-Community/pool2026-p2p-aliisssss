// SPDX-License-Identifier: MIT
pragma solidity ^0.8.39;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract RewardToken is ERC20, Ownable {
        constructor() ERC20("Reward Token", "RWD") {
            uint256 initialSupply = 1000 * 10**18;
            _mint(msg.sender, initialSupply);
        }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}