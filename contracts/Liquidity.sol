// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";

error Liquidity__NotOwner();

contract Liquidity is IERC721Receiver, LiquidityManagement {
  struct Deposit {
    address owner;
    uint128 liquidity;
    address token0;
    address token1;
  }

  address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  uint24 public constant poolFee = 3000;

  INonfungiblePositionManager public immutable nonfungiblePositionManager;

  mapping(uint256 => Deposit) public deposits;

  constructor(
    INonfungiblePositionManager _nonfungiblePositionManager,
    address _factory,
    address _WETH9
  ) PeripheryImmutableState(_factory, _WETH9) {
    nonfungiblePositionManager = _nonfungiblePositionManager;
  }

  function onERC721Received(
    address operator,
    address,
    uint _tokenId,
    bytes calldata
  ) external override returns (bytes4) {
    _createDeposit(operator, _tokenId);
    return this.onERC721Received.selector;
  }

  function _createDeposit(address owner, uint256 tokenId) internal {
    (
      ,
      ,
      address token0,
      address token1,
      ,
      ,
      ,
      uint128 liquidity,
      ,
      ,
      ,

    ) = nonfungiblePositionManager.positions(tokenId);

    deposits[tokenId] = Deposit({
      owner: owner,
      liquidity: liquidity,
      token0: token0,
      token1: token1
    });
  }

  function mintNewPosition()
    external
    returns (
      uint256 tokenId,
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1
    )
  {
    uint256 amount0ToMint = 1000;
    uint256 amount1ToMint = 1000;

    TransferHelper.safeApprove(
      DAI,
      address(nonfungiblePositionManager),
      amount0ToMint
    );
    TransferHelper.safeApprove(
      USDC,
      address(nonfungiblePositionManager),
      amount1ToMint
    );

    INonfungiblePositionManager.MintParams
      memory params = INonfungiblePositionManager.MintParams({
        token0: DAI,
        token1: USDC,
        fee: poolFee,
        tickLower: TickMath.MIN_TICK,
        tickUpper: TickMath.MAX_TICK,
        amount0Desired: amount0ToMint,
        amount1Desired: amount1ToMint,
        amount0Min: 0,
        amount1Min: 0,
        recipient: address(this),
        deadline: block.timestamp + 30
      });

    (tokenId, liquidity, token0, token1) = nonfungiblePositionManager.mint(
      params
    );

    _createDeposit(msg.sender, tokenId);

    if (amount0 < amount0ToMint) {
      TransferHelper.safeApprove(DAI, address(nonfungiblePositionManager), 0);
      uint256 refund0 = amount0ToMint - amount0;
      TransferHelper.safeTransfer(DAI, msg.sender, refund0);
    }

    if (amount1 < amount1ToMint) {
      TransferHelper.safeApprove(USDC, address(nonfungiblePositionManager), 0);
      uint256 refund1 = amount1ToMint - amount1;
      TransferHelper.safeTransfer(USDC, msg.sender, refund1);
    }
  }

  function collectAllFees(
    uint256 tokenId
  ) external returns (uint256 amount0, uint256 amount1) {
    nonfungiblePositionManager.safeTransferFrom(
      msg.sender,
      address(this),
      tokenId
    );

    INonfungiblePositionManager.CollectParams
      memory params = INonfungiblePositionManager.CollectParams({
        tokenId: tokenId,
        recipient: address(this),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })(amount0, amount1) = nonfungiblePositionManager.collect(params);

    _sendToOwner(tokenId, amount0, amount1);
  }

  function _sendToOwner(
    uint256 tokenId,
    uint256 amount0,
    uint256 amount1
  ) internal {
    address owner = deposits[tokenId].owner;
    address token0 = deposits[tokenId].token0;
    address token1 = deposits[tokenId].token1;

    TransferHelper.safeTransfer(token0, owner, amount0);
    TransferHelper.safeTransfer(token1, owner, amount1);
  }

  function decreaseLiquidity(
    uint128 liquidity
  ) external returns (amount0, amount1) {
    if (msg.sender != deposits[tokenId].owner) {
      revert Liquidity__NotOwner();
    }
    INonfungiblePositionManager.decreaseLiquidityParams
      memory params = INonfungiblePositionManager.decreaseLiquidityParams({
        tokenId: tokenId,
        liquidit: liquidity,
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp + 15
      });

    (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);

    _sendToOwner(tokenId, amount0, amount1);
  }

  function _sendToOwner(
    uint256 tokenId,
    uint256 amount0,
    uint256 amount1
  ) internal {
    address owner = deposits[tokenId].owner;

    address token0 = deposits[tokenId].token0;
    address token1 = deposits[tokenId].token1;
    TransferHelper.safeTransfer(token0, owner, amount0);
    TransferHelper.safeTransfer(token1, owner, amount1);
  }

  function increaseLiquidity(
    uint256 tokenId,
    uint256 amountAdd0,
    uint256 amountAdd1
  ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
    TransferHelper.safeTransfer(
      deposits[tokenId].token0,
      msg.sender,
      address(this),
      amountAdd0
    );
    TransferHelper.safeTransfer(
      deposits[tokenId].token1,
      msg.sender,
      address(this),
      amountAdd1
    );

    TransferHelper.safeApprove(
      deposits[tokenId].token0,
      address(nonfungiblePositionManager),
      amountAdd0
    );

    TransferHelper.safeApprove(
      deposits[tokenId].token1,
      address(nonfungiblePositionManager),
      amountAdd1
    );

    INonfungiblePositionManager.increaseLiquidityParams
      memory params = INonfungiblePositionManager.increaseLiquidityParams({
        tokenId: tokenId,
        amount0Desired: amountAdd0,
        amount1Desired: amountAdd1,
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp + 15
      });

    (liquidity, amount0, amount1) = nonfungiblePositionManager
      .increaseLiquidity(params);
  }

  function retrieveNFT(uint256 tokenId) external {
    if (msg.sender != deposits[tokenId].owner) {
      revert Liquidity__NotOwner();
    }

    nonfungiblePositionManager.safeTransferFrom(
      address(this),
      msg.sender,
      tokenId
    );

    delete deposits[tokenId];
  }
}
