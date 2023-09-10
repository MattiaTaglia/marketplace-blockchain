// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
  AggregatorV3Interface internal immutable priceFeed;

  /**
   * 
   * @param _priceFeed - Price Feed address
   * 
   * Network: Mumbai
   * Aggregator: ETH/USD
   * Address: 0x0715A7794a1dc8e42615F059dD6e406A6594651A
   * 
   * Network: Mumbai
   * Aggregator: MATIC/USD
   * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
   */
  constructor (address _priceFeed) {
    priceFeed = AggregatorV3Interface(_priceFeed);
  }


  function getLatestPrice() public view returns (int256) {
    // prettier-ignore
    (
        /* uint80 roundID */,
        int256 price,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
    ) = priceFeed.latestRoundData();
    return price;
  }

  function getPriceDecimals() public view returns (uint8) {
    return uint8(priceFeed.decimals());
  } 

  function getPriceFeed() public view returns (AggregatorV3Interface) {
    return priceFeed;
  }
  
}