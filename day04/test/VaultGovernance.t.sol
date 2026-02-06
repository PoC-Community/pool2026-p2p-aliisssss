// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock", "MCK") {}
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract VaultGovernanceTest is Test {
    Vault vault;
    MockERC20 token;
    address owner = address(0x1);
    address governor = address(0x2);
    address user = address(0x3);

    function setUp() public {
        vm.startPrank(owner);
        token = new MockERC20();
        vault = new Vault(address(token));
        vault.setGovernor(governor);
        vm.stopPrank();

        token.mint(user, 1000e18);
        vm.prank(user);
        token.approve(address(vault), type(uint256).max);
    }

    function testSetWithdrawalFee() public {
        vm.prank(governor);
        vault.setWithdrawalFee(500);
        assertEq(vault.withdrawalFeeBps(), 500);
    }

    function testNonGovernorCannotSetFee() public {
        vm.prank(user);
        vm.expectRevert(Vault.OnlyGovernor.selector);
        vault.setWithdrawalFee(100);
    }

    function testFeeCannotExceedMax() public {
        vm.prank(governor);
        vm.expectRevert(Vault.FeeTooHigh.selector);
        vault.setWithdrawalFee(1500); 
    }

    function testWithdrawalWithFee() public {
        vm.prank(governor);
        vault.setWithdrawalFee(250);

        uint256 depositAmount = 1000;
        vm.startPrank(user);
        vault.deposit(depositAmount);
        
        assertEq(token.balanceOf(user), 1000e18 - depositAmount);

        uint256 shares = vault.sharesOf(user);
        vault.withdraw(shares);
        vm.stopPrank();


        uint256 expectedReturn = 975;
        uint256 finalBalance = 1000e18 - depositAmount + expectedReturn;
        
        assertEq(token.balanceOf(user), finalBalance, "User should receive amount minus fee");
        assertEq(token.balanceOf(address(vault)), 25, "Fee should remain in vault");
    }
    
    function testOnlyOwnerCanSetGovernor() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vault.setGovernor(user);

        vm.prank(owner);
        vault.setGovernor(user);
        assertEq(vault.governor(), user);
    }
}
