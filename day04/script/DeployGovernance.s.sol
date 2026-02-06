pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Vault.sol";
import "../src/PoolToken.sol";
import "../src/VaultGovernor.sol";

contract DeployGovernance is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        uint256  VOTING_DELAY = 1 ; 
        uint256  VOTING_PERIOD = 50; 
        uint256  QUORUM_PERCENTAGE = 4;

        vm.startBroadcast(deployerKey);

        PoolToken token = new PoolToken(1_000_000 ether);

        Vault vault = new Vault(address(token));
         VaultGovernor vaultgov  = new VaultGovernor(
            IVotes(address(token)), 
            VOTING_DELAY, 
            VOTING_PERIOD, 
            QUORUM_PERCENTAGE
        );
        vault.setGovernor(address(vaultgov));
        token.delegate(msg.sender);
        vm.stopBroadcast();

        console2.log("Token deployed at:", address(token));
        console2.log("Vault deployed at:", address(vault));
        console2.log("Vaultgov deployed at:", address(vaultgov));
        
    }
}
