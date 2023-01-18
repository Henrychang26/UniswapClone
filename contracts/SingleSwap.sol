// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

error SingleSwap_MustBeGreaterThanZero();

contract SingleSwap {
  ISwapRouter public immutable swapRouter =
    ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  function convertEthToExactDai(
    address tokenIn,
    address tokenOut,
    uint256 amountIn
  ) external payable returns (uint256 amountOut) {
    if (amountIn <= 0) {
      revert SingleSwap_MustBeGreaterThanZero();
    }

    TransferHelper.safeTransferFrom(
      tokenIn,
      msg.sender,
      address(this),
      amountIn
    );
    TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
      .ExactInputSingleParams({
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        fee: 3000,
        recipient: msg.sender,
        deadline: block.timestamp + 30,
        amountIn: amountIn,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      });
    amountOut = swapRouter.exactInputSingle(params);
  }

  function swapExactOutputSingle(
    address tokenIn,
    address tokenOut,
    uint amountOut,
    uint amountInMaximum
  ) external returns (uint256 amountIn) {
    TransferHelper.safeTransferFrom(
      tokenIn,
      msg.sender,
      address(this),
      amountInMaximum
    );
    TransferHelper.safeApprove(tokenIn, address(swapRouter), amountInMaximum);

    ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
      .ExactOutputSingleParams({
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        fee: 3000,
        recipient: msg.sender,
        deadline: block.timestamp + 30,
        amountOut: amountOut,
        amountInMaximum: amountInMaximum,
        sqrtPriceLimitX96: 0
      });

    amountIn = swapRouter.exactOutputSingle(params);

    if (amountIn < amountInMaximum) {
      TransferHelper.safeApprove(tokenIn, address(swapRouter), 0);
      TransferHelper.safeTransfer(
        tokenIn,
        msg.sender,
        amountInMaximum - amountIn
      );
    }
  }
}
