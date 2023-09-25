// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract CustomMatic is ERC20, ERC20Burnable {
  address bridge;

  constructor() ERC20("CustomMatic", "C-MATIC") {
    //bridge = _bridge;
  }

/*   modifier onlyBridge {
    require(
      bridge == msg.sender,
      "Only the bridge can trigger this method!"
    );
    _;
  } */

  function mint(address _recipient, uint256 _amount) public virtual /* onlyBridge */ {
    _mint(_recipient, _amount);
  }

  function burnFrom(address _account, uint256 _amount) public virtual override(ERC20Burnable) /* onlyBridge */ {
    super.burnFrom(_account, _amount);
  }
}