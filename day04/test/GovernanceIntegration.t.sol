// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PoolToken.sol";
import "../src/VaultGovernor.sol";
import "../src/Vault.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract GovernanceIntegrationTest is Test {
    PoolToken token;
    VaultGovernor governor;
    Vault vault;

    address voter = address(0x123);
    uint256 constant INITIAL_SUPPLY = 10000e18;
    
    uint256 constant VOTING_DELAY = 1 days; 
    uint256 constant VOTING_PERIOD = 1 weeks; 
    uint256 constant QUORUM_PERCENTAGE = 4;

    function setUp() public {
        vm.startPrank(voter);
        token = new PoolToken(INITIAL_SUPPLY);
        
        token.delegate(voter);
        vm.stopPrank();

        governor = new VaultGovernor(
            IVotes(address(token)), 
            VOTING_DELAY, 
            VOTING_PERIOD, 
            QUORUM_PERCENTAGE
        );

        vault = new Vault(address(token)); 
        vault.setGovernor(address(governor));
    }

    function testFullGovernanceWorkflow() public {
        
        address[] memory targets = new address[](1);
        targets[0] = address(vault);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(Vault.setWithdrawalFee.selector, 250); // 2.5%

        string memory description = "Proposal #1: Set Withdrawal Fee to 2.5%";
        
        vm.prank(voter);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Pending));

        
        vm.roll(block.number + VOTING_DELAY + 1);
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Active));


        vm.prank(voter);
        governor.castVote(proposalId, 1);

        
        vm.roll(block.number + VOTING_PERIOD + 1);
        
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Succeeded));

        
        bytes32 descriptionHash = keccak256(bytes(description));
        governor.execute(targets, values, calldatas, descriptionHash);

        
        assertEq(vault.withdrawalFeeBps(), 250);
    }

    function testCannotVoteTwice() public {
        address[] memory targets = new address[](1);
        targets[0] = address(vault);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodePacked("");
        string memory description = "Simple Proposal";

        vm.prank(voter);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.startPrank(voter);
        governor.castVote(proposalId, 1);

        vm.expectRevert();
        governor.castVote(proposalId, 1);
        vm.stopPrank();
    }

    function testProposalFailsWithoutQuorum() public {
        address poorVoter = address(0x999);
        uint256 poorAmount = (INITIAL_SUPPLY * 3) / 100; 
        
        vm.prank(voter);
        token.transfer(poorVoter, poorAmount);
        
        vm.prank(poorVoter);
        token.delegate(poorVoter);
        
        vm.roll(block.number + 1);

        address[] memory targets = new address[](1);
        targets[0] = address(vault);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodePacked("");
        string memory description = "Failing Proposal";

        vm.prank(poorVoter);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(poorVoter);
        governor.castVote(proposalId, 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Defeated));
    }
}
