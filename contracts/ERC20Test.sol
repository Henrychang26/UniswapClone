// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Test is ERC20 {
  address payable i_owner;
  uint256 private s_initialSuppy = 1000000;

  constructor(uint256 initialSuppy) ERC20("Test", "TT") {
    s_initialSuppy = initialSuppy;
    i_owner = payable(msg.sender);
    _mint(i_owner, 10000);
  }
}
