// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./CustomMatic.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";

contract Bridge {
  CustomMatic customMatic;

  constructor(address _customMatic) {
    customMatic = CustomMatic(_customMatic);
  }

  event BridgeToken(address recipient, uint256 amountToMint);

  function bridgeToken(uint256 amountToMint) public payable {
    require(msg.value > 0, "token required");

    console.log(msg.value, amountToMint);

    customMatic.mint(msg.sender, amountToMint);
    address(0x0000000000000000000000000000000000000000).call{value: msg.value};
    console.log("bridge balance: ", address(this).balance);

    emit BridgeToken(msg.sender, amountToMint);
  }
}