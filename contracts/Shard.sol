// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Shard is ERC20, Ownable {
  constructor(uint256 _supply) ERC20("Shard", "SHD") {
    _mint(msg.sender, _supply * 10 ** 18);
  }
}