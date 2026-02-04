pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/ProfileSystem.sol";


contract ProfileTest is Test {
    ProfileSystem public system;
    address user1 = address(0x1);
    address user2 = address(0x2);
    function setUp() public {
        system = new ProfileSystem();
    }

    function testCreateProfile() public {
        vm.startPrank(user1);  // Simulate user1 calling
        system.createProfile("Alice");

        // Read from public mapping
        (string memory name, uint256 level, , ) = system.profiles(user1);

        assertEq(name, "Alice");
        assertEq(level, 1);
        vm.stopPrank();
    }

    function testCannotCreateEmptyProfile() public {
        vm.startPrank(user1);
        vm.expectRevert(ProfileSystem.EmptyUsername.selector);
        system.createProfile("");
        vm.stopPrank();
    }
    function testCannotCreateDuplicateProfile() public {
        vm.startPrank(user1);

        system.createProfile("Alice");

        vm.expectRevert(
            abi.encodeWithSelector(
                ProfileSystem.UserAlreadyExists.selector,
                user1
            )
        );
        system.createProfile("AliceAgain");

        vm.stopPrank();
    }

    function testLevelUp() public {
        vm.startPrank(user1);

        system.createProfile("Alice");
        system.levelUp();

        (, uint256 level, , ) = system.profiles(user1);
        assertEq(level, 2);

        vm.stopPrank();
    }

    function testCannotLevelUpIfNotRegistered() public {
        vm.startPrank(user2);

        vm.expectRevert(ProfileSystem.UserNotRegistered.selector);
        system.levelUp();

        vm.stopPrank();
    }
}