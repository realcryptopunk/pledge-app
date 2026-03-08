// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISwapRouter} from "../../src/interfaces/ISwapRouter.sol";
import {MockERC20} from "./MockERC20.sol";

/// @notice Simulates Uniswap V3 swaps for tests.
///         Pulls tokenIn from the caller, mints tokenOut to recipient.
///         Default rate is 1:1. Use setRate() to configure custom rates.
contract MockSwapRouter is ISwapRouter {
    using SafeERC20 for IERC20;

    // rate is in 1e18 fixed-point: amountOut = amountIn * rate / 1e18
    // rate = 1e18  => 1:1
    // rate = 2e18  => 2x output
    mapping(address => mapping(address => uint256)) public exchangeRate;

    function setRate(address tokenIn, address tokenOut, uint256 rate) external {
        exchangeRate[tokenIn][tokenOut] = rate;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        override
        returns (uint256 amountOut)
    {
        // Pull tokenIn from caller (vault must have approved this contract)
        IERC20(params.tokenIn).safeTransferFrom(
            msg.sender, address(this), params.amountIn
        );

        uint256 rate = exchangeRate[params.tokenIn][params.tokenOut];
        if (rate == 0) rate = 1e18; // default 1:1

        amountOut = (params.amountIn * rate) / 1e18;

        // Mint tokenOut to recipient
        MockERC20(params.tokenOut).mint(params.recipient, amountOut);
    }
}
