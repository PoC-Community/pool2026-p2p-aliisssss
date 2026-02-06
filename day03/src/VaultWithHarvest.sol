// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2.sol";

/**
 * @title VaultWithHarvest
 * @notice Advanced DeFi Vault with Uniswap integration for auto-compound rewards
 *
 * @dev Architecture:
 *
 * ┌─────────────────────────────────────────────────────────────────────────┐
 * │                        VAULT ARCHITECTURE                               │
 * │                                                                         │
 * │   1. Users deposit POOL tokens                                          │
 * │   2. Vault receives RWRD tokens as rewards                              │
 * │   3. harvest() swaps RWRD → POOL via Uniswap                            │
 * │   4. Added POOL increases share value                                   │
 * │                                                                         │
 * │   [User] ──deposit()──▶ [Vault] ◀──RWRD rewards                         │
 * │                            │                                            │
 * │                            ▼                                            │
 * │                       harvest()                                         │
 * │                            │                                            │
 * │                            ▼                                            │
 * │                      [Uniswap]                                          │
 * │                    RWRD ──▶ POOL                                        │
 * │                            │                                            │
 * │                            ▼                                            │
 * │                  Ratio shares/POOL ↑                                    │
 * └─────────────────────────────────────────────────────────────────────────┘
 */
contract VaultWithHarvest is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
      // ═══════════════════════════════════════════════════════════════════════════
    //                              STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════

    /// @notice Main vault token (POOL) - users deposit this token
    IERC20 public immutable asset;

    /// @notice Reward token (RWRD) - will be swapped to asset
    IERC20 public immutable rewardToken;

    /// @notice Uniswap V2 Router for swaps
    IUniswapV2Router02 public immutable uniswapRouter;

    /// @notice Total shares issued
    uint256 public totalShares;

    /// @notice Mapping of shares per user
    mapping(address => uint256) public sharesOf;

    // ═══════════════════════════════════════════════════════════════════════════
    //                            HARVEST CONFIGURATION
    // ═══════════════════════════════════════════════════════════════════════════

    /// @notice Maximum slippage tolerated for swaps (in basis points, 100 = 1%)
    uint256 public maxSlippage = 100; // 1% by default

    /// @notice Last harvest timestamp
    uint256 public lastHarvestTime;

    /// @notice Minimum delay between two harvests (anti-spam)
    uint256 public harvestCooldown = 1 hours;

    /// @notice Total rewards converted to asset
    uint256 public totalHarvested;
    // ═══════════════════════════════════════════════════════════════════════════
    //                                  EVENTS
    // ═══════════════════════════════════════════════════════════════════════════

    event Deposit(address indexed user, uint256 assets, uint256 shares);
    event Withdraw(address indexed user, uint256 assets, uint256 shares);
    event Harvest(
        address indexed caller,
        uint256 rewardAmount,
        uint256 assetReceived
    );
    event SlippageUpdated(uint256 oldSlippage, uint256 newSlippage);
    event CooldownUpdated(uint256 oldCooldown, uint256 newCooldown);
     // ═══════════════════════════════════════════════════════════════════════════
    //                                  ERRORS
    // ═══════════════════════════════════════════════════════════════════════════

    error ZeroAmount();
    error InvalidAddress();
    error InsufficientShares(uint256 requested, uint256 available);
    error NoStakers();
    error ZeroSharesMinted();
    error ZeroAssetsToWithdraw();
    error NoRewardsToHarvest();
    error HarvestCooldownNotMet(uint256 timeRemaining);
    error SlippageTooHigh(uint256 expected, uint256 received);
    error InvalidSlippage();
    // ═══════════════════════════════════════════════════════════════════════════
    //                                CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Deploys the vault with Uniswap integration
     * @param asset_ Main token (POOL)
     * @param rewardToken_ Reward token (RWRD)
     * @param uniswapRouter_ Uniswap V2 Router address
     *
     * Uniswap V2 Router addresses:
     * - Ethereum Mainnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
     * - Sepolia Testnet: 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008 (or deploy your own)
     */
    constructor(
        address asset_,
        address rewardToken_,
        address uniswapRouter_
    ) Ownable(msg.sender) {
        if (asset_ == address(0)) revert InvalidAddress();
        if (rewardToken_ == address(0)) revert InvalidAddress();
        if (uniswapRouter_ == address(0)) revert InvalidAddress();

        asset = IERC20(asset_);
        rewardToken = IERC20(rewardToken_);
        uniswapRouter = IUniswapV2Router02(uniswapRouter_);

        lastHarvestTime = block.timestamp;
    }
     // ═══════════════════════════════════════════════════════════════════════════
    //                            INTERNAL FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @dev Converts assets to shares
     */
    function _convertToShares(uint256 assets) internal view returns (uint256) {
        uint256 totalAssets_ = asset.balanceOf(address(this));

        if (totalShares == 0 || totalAssets_ == 0) {
            return assets;
        }

        return (assets * totalShares) / totalAssets_;
    }

    /**
     * @dev Converts shares to assets
     */
    function _convertToAssets(uint256 shares) internal view returns (uint256) {
        if (totalShares == 0) {
            return 0;
        }

        uint256 totalAssets_ = asset.balanceOf(address(this));
        return (shares * totalAssets_) / totalShares;
    }
     // ═══════════════════════════════════════════════════════════════════════════
    //                            DEPOSIT / WITHDRAW
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Deposits assets and receives shares
     */
    function deposit(
        uint256 assets
    ) external nonReentrant returns (uint256 shares) {
        // TODO: Implement (same as Exercise 02)
        // 1. Check assets > 0
        // 2. Calculate shares with _convertToShares
        // 3. Check shares > 0
        // 4. Update totalShares and sharesOf[msg.sender]
        // 5. Transfer assets from user to vault
        // 6. Emit Deposit event
    }

    /**
     * @notice Withdraws assets by burning shares
     */
    function withdraw(
        uint256 shares
    ) external nonReentrant returns (uint256 assets) {
        // TODO: Implement (same as Exercise 02)
    }

    /**
     * @notice Withdraws all user's assets
     */
    function withdrawAll() external nonReentrant returns (uint256 assets) {
        // TODO: Implement
    }
    /**
     * @notice Calculates the expected output amount for a swap
     * @param rewardAmount Amount of reward tokens to swap
     * @return expectedAsset Amount of asset tokens expected
     *
     * @dev Uses Uniswap's getAmountsOut to get current price
     */
    function _getExpectedOutput(
        uint256 rewardAmount
    ) internal view returns (uint256) {
        if (rewardAmount == 0) return 0;

        address[] memory path = new address[](2);
        path[0] = address(rewardToken);
        path[1] = address(asset);

        try uniswapRouter.getAmountsOut(rewardAmount, path) returns (
            uint[] memory amounts
        ) {
            return amounts[1]; // amounts[0] = input, amounts[1] = output
        } catch {
            return 0; // Pool doesn't exist or no liquidity
        }
    }
        // ═══════════════════════════════════════════════════════════════════════════
    //                              HARVEST FUNCTION
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Converts accumulated reward tokens to asset tokens via Uniswap
     * @return assetReceived Amount of assets added to vault
     *
     * @dev This function is the heart of the DeFi integration:
     *
     * Execution flow:
     * 1. Verify there are rewards to harvest
     * 2. Verify cooldown
     * 3. Calculate acceptable minimum (slippage protection)
     * 4. Approve the router
     * 5. Execute the swap RWRD → POOL
     * 6. The received POOL stays in the vault, increasing the ratio
     *
     * Security:
     * - Slippage protection against sandwich attacks
     * - Cooldown to prevent spam
     * - Anyone can call (decentralized)
     *
     * Note on decentralization:
     * Allowing anyone to call harvest() is a common practice:
     * - "Keepers" or bots can automate the harvest
     * - No dependency on a centralized entity
     * - Works like Yearn, Beefy, etc.
     */
    function harvest() external nonReentrant returns (uint256 assetReceived) {
        // ═══════════════════════════════════════════════════════════════════
        // STEP 1: CHECKS - Pre-conditions verification
        // ═══════════════════════════════════════════════════════════════════

        // TODO: Get the vault's rewardToken balance
        uint256 rewardBalance = 
        
        // TODO: Check there are rewards (otherwise revert NoRewardsToHarvest)

        // TODO: Calculate time since last harvest
        // uint256 timeSinceLastHarvest = block.timestamp - lastHarvestTime;
        
        // TODO: Check cooldown (otherwise revert HarvestCooldownNotMet with remaining time)

        // TODO: Check there are stakers (otherwise revert NoStakers)

        // ═══════════════════════════════════════════════════════════════════
        // STEP 2: EFFECTS - State updates
        // ═══════════════════════════════════════════════════════════════════

        // TODO: Update lastHarvestTime to current timestamp

        // ═══════════════════════════════════════════════════════════════════
        // STEP 3: INTERACTIONS - External call to Uniswap
        // ═══════════════════════════════════════════════════════════════════

        // TODO: Calculate acceptable minimum with _getExpectedOutput
        //       and apply slippage: minOutput = expected * (10000 - maxSlippage) / 10000
        // uint256 expectedOutput = _getExpectedOutput(rewardBalance);
        // uint256 minOutput = ...

        // TODO: Approve the Uniswap router to spend reward tokens
        //       Use safeIncreaseAllowance (from SafeERC20)
        // rewardToken.safeIncreaseAllowance(address(uniswapRouter), rewardBalance);

        // TODO: Build the swap path
        // address[] memory path = new address[](2);
        // path[0] = address(rewardToken);
        // path[1] = address(asset);

        // TODO: Record the asset balance BEFORE the swap
        // uint256 assetBalanceBefore = asset.balanceOf(address(this));

        // TODO: Call uniswapRouter.swapExactTokensForTokens(...)
        //       - amountIn: rewardBalance
        //       - amountOutMin: minOutput
        //       - path: path
        //       - to: address(this)
        //       - deadline: block.timestamp

        // TODO: Calculate assetReceived = balance after - balance before

        // TODO: Additional slippage verification
        //       if (assetReceived < minOutput) revert SlippageTooHigh(minOutput, assetReceived);

        // TODO: Update totalHarvested
        // totalHarvested += assetReceived;

        // TODO: Emit the Harvest event
        // emit Harvest(msg.sender, rewardBalance, assetReceived);
    }
}