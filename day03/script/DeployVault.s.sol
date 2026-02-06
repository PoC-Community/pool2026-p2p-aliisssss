pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Vault.sol";
import "../test/mocks/MaliciousToken.sol";

contract DeployVault is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        MaliciousToken token = new MaliciousToken();

        Vault vault = new Vault(address(token));

        vm.stopBroadcast();

        console2.log("Token deployed at:", address(token));
        console2.log("Vault deployed at:", address(vault));
    }
}
