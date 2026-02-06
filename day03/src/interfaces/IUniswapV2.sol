// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IUniswapV2Router02
 * @notice Simplified Uniswap V2 Router interface
 *
 * @dev Uniswap V2 is simpler than V3 for learning:
 *      - No concentrated liquidity management
 *      - No position NFT
 *      - Single function for swaps
 *
 * Official documentation:
 * https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02
 */
interface IUniswapV2Router02 {
    /**
     * @notice Swap an exact amount of input tokens for a minimum of output tokens
     * @param amountIn Exact amount of tokens to send
     * @param amountOutMin Minimum amount of tokens to receive (slippage protection)
     * @param path Swap path: [tokenIn, ..., tokenOut]
     * @param to Address that receives the output tokens
     * @param deadline Timestamp limit to execute the transaction
     * @return amounts Array of amounts: [amountIn, ..., amountOut]
     *
     * Path examples:
     * - [RWRD, POOL] → direct swap RWRD to POOL
     * - [RWRD, WETH, POOL] → swap via WETH if no direct pool
     *
     * Slippage protection:
     * - amountOutMin prevents sandwich attacks
     * - Typically 0.5% to 1% tolerance
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    /**
     * @notice Add liquidity to a pair
     * @param tokenA First token of the pair
     * @param tokenB Second token of the pair
     * @param amountADesired Desired amount of tokenA
     * @param amountBDesired Desired amount of tokenB
     * @param amountAMin Minimum amount of tokenA (slippage)
     * @param amountBMin Minimum amount of tokenB (slippage)
     * @param to Address that receives LP tokens
     * @param deadline Timestamp limit
     * @return amountA Actual amount of tokenA added
     * @return amountB Actual amount of tokenB added
     * @return liquidity Amount of LP tokens received
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    /**
     * @notice Returns the output amount for a given input amount
     * @param amountIn Amount of input tokens
     * @param path Swap path
     * @return amounts Array of amounts at each step
     *
     * Useful for:
     * - Preview a swap before execution
     * - Calculate amountOutMin with slippage
     */
    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    /// @notice Address of the Uniswap V2 factory
    function factory() external pure returns (address);

    /// @notice Address of WETH (Wrapped ETH)
    function WETH() external pure returns (address);
}

/**
 * @title IUniswapV2Factory
 * @notice Uniswap V2 Factory interface
 *
 * @dev The factory manages creation and tracking of liquidity pairs
 */
interface IUniswapV2Factory {
    /**
     * @notice Creates a new liquidity pair
     * @param tokenA First token
     * @param tokenB Second token
     * @return pair Address of the newly created pair
     *
     * Note: The pair is created if it doesn't exist already
     */
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    /**
     * @notice Returns the address of an existing pair
     * @param tokenA First token
     * @param tokenB Second token
     * @return pair Address of the pair (or address(0) if non-existent)
     */
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

/**
 * @title IUniswapV2Pair
 * @notice Uniswap V2 liquidity pair interface
 */
interface IUniswapV2Pair {
    /// @notice Returns the reserves of the pair
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    /// @notice First token of the pair
    function token0() external view returns (address);

    /// @notice Second token of the pair
    function token1() external view returns (address);
}