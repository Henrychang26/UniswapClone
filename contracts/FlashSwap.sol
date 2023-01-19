// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";

import "@uniswap/v3-periphery/contracts/base/PeripheryPayments.sol";
import "@uniswap/v3-periphery/contracts/base/PeripheryImmutableState.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract Flash is IUniswapV3FlashCallback, PeripheryPayments {
  using LowGasSafeMath for uint256;
  using LowGasSafeMath for int256;

  struct FlashParams {
    address token0;
    address token1;
    uint24 fee1;
    uint256 amount0;
    uint256 amount1;
    uint24 fee2;
    uint24 fee3;
  }

  struct FlashCallbackData {
    uint256 amount0;
    uint256 amount1;
    address payer;
    PoolAddress.PoolKey poolKey;
    uint24 poolFee2;
    uint24 poolFee3;
  }

  ISwapRouter private immutable swapRouter;

  constructor(
    ISwapRouter _swapRouter,
    address _factory,
    address _WETH9
  ) PeripheryImmutableState(_factory, _WETH9) {
    swapRouter = _swapRouter;
  }

  function initFlash(FlashParams memory params) external {
    //Find specific key
    PoolAddress.poolKey memory poolKey = PoolAddress.poolKey({
      token0: params.token0,
      token1: params.token1,
      fee: params.fee1
    });

    //Find specific pool using tokne0, token1, fee to calculate pool address
    IUniswapV3Pool pool = IUniswapV3Pool(
      PoolAddress.computeAddress(factory, poolKey)
    );

    pool.flash(
      address(this),
      params.amount0,
      params.amount1,
      abi.encode(
        flaFlashCallbackData({
          amount0: params.amount0,
          amount1: params.amount1,
          payer: msg.sender,
          poolKey: poolKey,
          poolFee2: params.fee2,
          poolFee3: params.fee3
        })
      )
    );
  }

  function uniswapV3FlashCallback(
    uint256 fee0,
    uint256 fee1,
    bytes calldata data
  ) external override {
    FlashCallbackData memory decoded = abi.decode(data, (FlashCallbackData));
    CallbackValidation.verifyCallback(factory, decoded.poolKey);

    uint256 amount1Min = LowGasSafeMath.add(decoded.amount1, fee1);
    uint256 amount0Min = LowGasSafeMath.add(decoded.amount0, fee0);

    uint256 amountOut0 = swapRouter.exactInputSingle(
      ISwapRouter.exactInputSingleparams({
        tokenIn: token1,
        tokenout: token0,
        fee: decoded.poolFee2,
        recipient: address(this),
        deadlineL: block.timestamp,
        amountIn: decoded.amount1,
        amountOutMinimum: amount0Min,
        sqrtPriceLimitX96: 0
      })
    );

    uint256 amountOut1 = swapRouter.exactInputSingle(
      ISwapRouter.ExactInputSingleParams({
        tokenIn: token0,
        tokenOut: token1,
        fee: decoded.poolFee3,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: decoded.amount0,
        amountOutMinimum: amount1Min,
        sqrtPriceLimitX96: 0
      })
    );

    //Calculate how much owed (amount + fee)
    uint256 amount0Owed = LowGasSafeMath.add(decoded.amount0, fee0);
    uint256 amount1Owed = LowGasSafeMath.add(decoded.amount1, fee1);

    TransferHelper.safeApprove(token0, address(this), amount0Owed);
    TransferHelper.safeApprove(token1, address(this), amount1Owed);

    //Pay back function
    if (amount0Owed > 0) pay(token0, address(this), msg.sender, amount0Owed);
    if (amount1Owed > 0) pay(token1, address(this), msg.sender, amount1Owed);

    //Calculates differnce and sends profit to this contract
    if (amountOut0 > amount0Owed) {
      uint256 profit0 = LowGasSafeMath.sub(amountOut0, amount0Owed);

      TransferHelper.safeApprove(token0, address(this), profit0);
      pay(token0, address(this), decoded.payer, profit0);
    }
    if (amountOut1 > amount1Owed) {
      uint256 profit1 = LowGasSafeMath.sub(amountOut1, amount1Owed);
      TransferHelper.safeApprove(token0, address(this), profit1);
      pay(token1, address(this), decoded.payer, profit1);
    }
  }
}