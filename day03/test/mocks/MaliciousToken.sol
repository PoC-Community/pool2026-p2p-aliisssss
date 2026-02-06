// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../src/Vault.sol";

contract MaliciousToken is ERC20 {
    address public vault;
    bool public attacking;
    uint256 public attackCount;

    constructor() ERC20("Malicious Token", "MAL") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }

    function setVault(address _vault) external {
        vault = _vault;
    }

    function enableAttack(bool _attacking) external {
        attacking = _attacking;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (attacking && msg.sender == vault) {
            if (attackCount < 3) {
                attackCount++;
                Vault(vault).withdraw(amount);
            }
        }
        return super.transfer(to, amount);
    }
}