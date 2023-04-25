// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract MultiHop {
  ISwapRouter public immutable swapRouter =
    ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address public constant token0 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant token1 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  //     address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //DAI
  //     address public constant token0 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //WETH
  //     address public constant token1 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //USDC

  function swapExactInputMultihop(
    uint256 amountIn
  ) external returns (uint256 amountOut) {
    TransferHelper.safeTransferFrom(
      token0,
      msg.sender,
      address(this),
      amountIn
    );
    TransferHelper.safeApprove(token0, address(swapRouter), amountIn);

    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      path: abi.encodePacked(token0, uint24(3000), token1, uint24(3000), DAI),
      recipient: msg.sender,
      deadline: block.timestamp + 30,
      amountIn: amountIn,
      amountOutMinimum: 0
    });

    amountOut = swapRouter.exactInput(params);
  }

  function swapExactOutputMultihop(
    uint256 amountOut,
    uint256 amountInMaximum
  ) external returns (uint256 amountIn) {
    TransferHelper.safeTransferFrom(
      token0,
      msg.sender,
      address(this),
      amountInMaximum
    );

    TransferHelper.safeApprove(token0, address(swapRouter), amountInMaximum);

    ISwapRouter.ExactOutputParams memory params = ISwapRouter
      .ExactOutputParams({
        path: abi.encodePacked(DAI, uint24(3000), token1, uint24(3000), token0),
        recipient: msg.sender,
        deadline: block.timestamp + 30,
        amountOut: amountOut,
        amountInMaximum: amountInMaximum
      });
    amountIn = swapRouter.exactOutput(params);

    if (amountIn < amountInMaximum) {
      TransferHelper.safeApprove(token0, address(swapRouter), 0);
      TransferHelper.safeTransferFrom(
        token0,
        address(this),
        msg.sender,
        amountInMaximum - amountIn
      );
    }
  }
}
