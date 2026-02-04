pragma solidity ^0.8.20;

// src/ProfileSystem.sol

contract ProfileSystem {
    // ========== ENUMS ==========
    // TODO: Create enum Role { GUEST, USER, ADMIN }
    enum Role {
        GUEST,
        USER,
        ADMIN
    }

    // ========== STRUCTS ==========
    // TODO: Create struct UserProfile with:
    //   - string username
    //   - uint256 level
    //   - Role role
    //   - uint256 lastUpdated

    struct UserProfile {
        string username;
        uint256 level;
        Role role;
        uint256 lastUpdated;
    }

    // ========== MAPPINGS ==========
    // TODO: mapping(address => UserProfile) public profiles
    mapping(address => UserProfile) public profiles;

    // ========== CUSTOM ERRORS ==========
    // TODO: error UserAlreadyExists()
    error UserAlreadyExists(address userAddress);
    // TODO: error EmptyUsername()
    error EmptyUsername();

    // TODO: error UserNotRegistered()
    error UserNotRegistered();

    modifier onlyRegistered() {
        if (profiles[msg.sender].level == 0) {
            revert UserNotRegistered();
        }
        _;
    }

    event ProfileCreated(address indexed user, string username);
    event LevelUp(address indexed user, uint256 newLevel);

    function createProfile(string calldata _name) external {
        if (bytes(_name).length == 0) {
            revert EmptyUsername();
        }
        if (profiles[msg.sender].level > 0) {
            revert UserAlreadyExists(msg.sender);
        }

        // Write directly to storage
        profiles[msg.sender] = UserProfile({
            username: _name,
            level: 1,
            role: Role.USER,
            lastUpdated: block.timestamp
        });

        emit ProfileCreated(msg.sender, _name);
    }

    /**
     * @notice Increase user level by 1
     * @dev Must use onlyRegistered modifier
     *   1. Increment profiles[msg.sender].level
     *   2. Update lastUpdated to block.timestamp
     */
    function levelUp() external onlyRegistered {
        // TODO: Implement
        profiles[msg.sender].level += 1;
        profiles[msg.sender].lastUpdated = block.timestamp;
        emit LevelUp(msg.sender, profiles[msg.sender].level);
    }
}

