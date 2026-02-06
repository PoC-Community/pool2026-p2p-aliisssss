pragma solidity ^0.8.0;
import "forge-std/Test.sol";

import "../src/PoolToken.sol";

contract PoolTokentest is Test {
    PoolToken public pooltok;
    address public alice;
    address public  owner;

    function setUp() public {
        owner  = address(this);
        alice = address(0x123);
        pooltok = new PoolToken(1000 * 10 ** 18);
    }

    function testInitialVotingPowerIsZero() public {
        vm.startPrank(alice);
        assertEq(pooltok.getVotes(alice), 0);
        vm.stopPrank();
    }
    function testDelegateToSelf() public {
        pooltok.delegate(owner);
        assertEq(pooltok.getVotes(owner),  1000 * 10 ** 18);
    }
    function testDelegateToOther() public {
        // vm.startPrank(alice);

        pooltok.delegate(owner);
        assertEq(pooltok.getVotes(owner), 1000 * 10 ** 18);
        assertEq(pooltok.getVotes(alice), 0);
        // vm.stopPrank();
    }

}

