pragma solidity ^0.8.0;
import "forge-std/Test.sol";

import "../src/PoolToken.sol";
import "../src/VaultGovernor.sol";

contract vaulttest is Test {
    VaultGovernor public vault;
    PoolToken public token;
    address public user = address(0x123);

    uint256 constant VOTING_DELAY = 1;
    uint256 constant VOTING_PERIOD = 50;
    uint256 constant QUORUM_PERCENTAGE = 4;
    address[] targets;
    uint256[] values;
    bytes[] calldatas;

    function setUp() public {
        token = new PoolToken(1_000_000 ether);

        vault = new VaultGovernor(
            IVotes(address(token)),
            VOTING_DELAY,
            VOTING_PERIOD,
            QUORUM_PERCENTAGE
        );

        token.delegate(user);

        vm.roll(block.number + 1);
    }


    function testGovernorParameters() public {
        vm.startPrank(user);
        assertEq(vault.votingDelay(), VOTING_DELAY);
        assertEq(vault.votingPeriod(), VOTING_PERIOD);
        assertEq(vault.name(), "VaultGovernor");
        vm.stopPrank();
    }

    function testQuorumCalculation() public {
        uint256 blockNumber = block.number - 1;
        uint256 quorum = vault.quorum(blockNumber);

        assertEq(quorum, 40_000 ether);
    }
    function testCreateProposal() public {
        token.delegate(user);
        vm.roll(block.number + 1);
        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature(
            "mint(address,uint256)",
            user,
            1 ether
        );

        vm.prank(user);
        uint256 proposalId = vault.propose(
            targets,
            values,
            calldatas,
            "Mint tokens to user"
        );

        assertGt(proposalId, 0);
    }



}