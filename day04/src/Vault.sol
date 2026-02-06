// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    uint256 public totalShares;
    mapping(address => uint256) public sharesOf;
    
    uint256 public withdrawalFeeBps;
    address public governor;
    uint256 public constant MAX_FEE = 1000;

    event Deposit(address indexed user, uint256 assets, uint256 shares);
    event Withdraw(address indexed user, uint256 assets, uint256 shares);
    event RewardAdded(uint256 amount);
    event WithdrawalFeeUpdated(uint256 oldFee, uint256 newFee);
    event GovernorUpdated(address indexed oldGovernor, address indexed newGovernor);

    error OnlyGovernor();
    error FeeTooHigh();
    error ZeroAmount();
    error ZeroShares();
    error InsufficientShares();

    constructor(address _asset) Ownable(msg.sender) {
        asset = IERC20(_asset);
    }

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert OnlyGovernor();
        }
        _;
    }

    function setGovernor(address newGovernor) external onlyOwner {
        address oldGovernor = governor;
        governor = newGovernor;
        emit GovernorUpdated(oldGovernor, newGovernor);
    }

    function setWithdrawalFee(uint256 newFeeBps) external onlyGovernor {
        if (newFeeBps > MAX_FEE) {
            revert FeeTooHigh();
        }
        uint256 oldFee = withdrawalFeeBps;
        withdrawalFeeBps = newFeeBps;
        emit WithdrawalFeeUpdated(oldFee, newFeeBps);
    }

    function _convertToShares(uint256 assets) internal view returns (uint256 shares) {
        uint256 totalManagedAssets = asset.balanceOf(address(this));
        if (totalShares == 0 || totalManagedAssets == 0) {
            return assets;
        }
        return (assets * totalShares) / totalManagedAssets;
    }

    function _convertToAssets(uint256 shares) internal view returns (uint256 assets) {
        if (totalShares == 0) return 0;
        uint256 totalManagedAssets = asset.balanceOf(address(this));
        return (shares * totalManagedAssets) / totalShares;
    }

    function deposit(uint256 assets) external nonReentrant returns (uint256 shares) {
        if (assets == 0) revert ZeroAmount();
        shares = _convertToShares(assets);
        if (shares == 0) revert ZeroShares();

        sharesOf[msg.sender] += shares;
        totalShares += shares;

        asset.safeTransferFrom(msg.sender, address(this), assets);
        emit Deposit(msg.sender, assets, shares);
    }

    function withdraw(uint256 shares) public nonReentrant returns (uint256 assets) {
        if (shares == 0) revert ZeroShares();
        if (sharesOf[msg.sender] < shares) revert InsufficientShares();

        uint256 assetsToReturn = _convertToAssets(shares);
        
        uint256 fee = (assetsToReturn * withdrawalFeeBps) / 10000;
        assets = assetsToReturn - fee; 

        sharesOf[msg.sender] -= shares;
        totalShares -= shares;

        asset.safeTransfer(msg.sender, assets);
        
        
        emit Withdraw(msg.sender, assets, shares);
    }

    function withdrawAll() public returns (uint256 assets) {
        assets = withdraw(sharesOf[msg.sender]);
    }

    function previewDeposit(uint256 assets) external view returns (uint256 shares) {
        shares = _convertToShares(assets);
    }

    function previewWithdraw(uint256 shares) external view returns (uint256 assets) {
        assets = _convertToAssets(shares);
    }

    function addReward(uint256 amount) external onlyOwner nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (totalShares == 0) revert ZeroShares();

        asset.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardAdded(amount);
    }

    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function currentRatio() external view returns (uint256) {
        if (totalShares == 0) return 1e18;
        return (asset.balanceOf(address(this)) * 1e18) / totalShares;
    }

    function assetsOf(address user) external view returns (uint256) {
        return _convertToAssets(sharesOf[user]);
    }
}
