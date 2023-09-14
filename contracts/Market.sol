// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Shard.sol";
import "./PriceConsumerV3.sol";
import "./ItemNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract Market is Ownable {

  uint256 public shardsPerMatic = 50;
  
  uint public constant usdDecimals = 2;
  uint public constant tokenDecimals = 18;

  //address public oracleEthUsdPrice;
  //address public oracleMaticUsdPrice; 

  uint256 public ownerMaticAmountToWithdraw;
  uint256 public ownerShardAmountToWithdraw;

  Shard shard;
  ItemSkin itemSkin;

  PriceConsumerV3 public ethUsdContract;
  PriceConsumerV3 public maticUsdContract;
  PriceConsumerV3 oracleContract;

  constructor(address tokenAddress, address nftAddress, 
    address oracleEthUsdPrice, address oracleMaticUsdPrice) {

    //oracleEthUsdPrice = address(0x0715A7794a1dc8e42615F059dD6e406A6594651A);
    //oracleMaticUsdPrice = address(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);

    ethUsdContract = PriceConsumerV3(oracleEthUsdPrice);
    maticUsdContract = PriceConsumerV3(oracleMaticUsdPrice);
    shard = Shard(tokenAddress);
    itemSkin = ItemSkin(nftAddress);

  }

  event BuyShardsInMatic(address buyer, uint256 amountOfMatic, uint256 amountOfShards);
  event BuyShardsInEth(address buyer, uint256 amountOfEth, uint256 amountOfShards);
  event BuyShardsInUsd(address buyer, uint256 amountOfUsd, uint256 amountOfShards);
  event BuyItemSkinInShard(address buyer, uint256 amountOfShards, uint256 amountOfSkin);


  function convertEthInUsd(uint weiAmount) public view returns (uint) {
    uint8 ethUsdPriceDecimals = ethUsdContract.getPriceDecimals();
    uint ethUsdPrice = uint(ethUsdContract.getLatestPrice());

    uint ethConvertedInUsd = (weiAmount * (ethUsdPrice * 10 ** (18 - ethUsdPriceDecimals))) / (10 ** (18 - ethUsdPriceDecimals));

    return ethConvertedInUsd; 
  }

  function convertUsdInEth(uint usdAmount) public view returns (uint){
    uint8 ethPriceDecimals = ethUsdContract.getPriceDecimals();
    uint ethPrice = uint(ethUsdContract.getLatestPrice());
    uint adjust_price = ethPrice * 10 ** (18 - ethPriceDecimals);
    
    uint usd = usdAmount * 10 ** 18;
    uint usdConvertedInEth = (usd * 10 ** 18) / adjust_price;
    
    return usdConvertedInEth;
  }

  function convertMaticInUsd(uint weiAmount) public view returns (uint) {
    uint8 maticUsdPriceDecimals = maticUsdContract.getPriceDecimals();
    uint maticUsdPrice = uint(maticUsdContract.getLatestPrice());

    uint maticConvertedInUsd = (weiAmount * (maticUsdPrice * 10 ** (18 - maticUsdPriceDecimals))) / (10 ** (18 - maticUsdPriceDecimals));

    return maticConvertedInUsd;  
  }

  function convertUsdInMatic(uint usdAmount) public view returns (uint) {
    uint8 maticPriceDecimals = maticUsdContract.getPriceDecimals();
    uint maticPrice = uint(maticUsdContract.getLatestPrice());
    uint adjust_price = maticPrice * 10 ** (18 - maticPriceDecimals);
    
    uint usd = usdAmount * 10 ** 18;
    uint usdConvertedInMatic = (usd * 10 ** 18) / adjust_price;

    return usdConvertedInMatic; 
  }

  /**
  * @notice Allow a user to buy Shards paying with MATIC
  */
  function buyShardsInMatic(uint256 amount) public payable {
    require(msg.value > 0, "MATIC needed to buy shards");

    uint256 vendorBalance = shard.balanceOf(address(this));
    require(vendorBalance >= amount, "Vendor contract has not enough shards in its balance");

    uint amountOfMaticRequired = (amount / shardsPerMatic) * (10 ** 18);
    require(msg.value >= amountOfMaticRequired, "Incorrect number of MATIC given for the wanted amount of shards");

    SafeERC20.safeTransfer(shard, msg.sender, amount);

    ownerMaticAmountToWithdraw += amountOfMaticRequired;

    emit BuyShardsInMatic(msg.sender, msg.value, amount);
  }

  /**
  * @notice Allow a user to buy Shards paying with ETH
  */
  function buyShardsInEth(uint256 amount) public payable {
    require(msg.value > 0, "ETH needed to buy shards");

    uint256 vendorBalance = shard.balanceOf(address(this));
    require(vendorBalance >= amount, "Vendor contract has not enough shards in its balance");

    uint256 amountOfUsdFromEth = convertEthInUsd(msg.value);
    uint256 amountOfMaticFromUsd = convertUsdInMatic(amountOfUsdFromEth); 

    uint amountOfMaticRequired = (amount / shardsPerMatic) * (10 ** 44);
    require(amountOfMaticFromUsd >= amountOfMaticRequired, "Incorrect number of MATIC given for the wanted amount of shards");

    SafeERC20.safeTransfer(shard, msg.sender, amount);

    ownerMaticAmountToWithdraw += amountOfMaticRequired;

    emit BuyShardsInEth(msg.sender, msg.value, amount);
  }

  /**
  * @notice Allow a user to buy Shards paying with USD
  */
  function buyShardsInUsd(uint256 amount) public payable {
    require(msg.value > 0, "USD needed to buy shards");

    uint256 vendorBalance = shard.balanceOf(address(this));
    require(vendorBalance >= amount, "Vendor contract has not enough shards in its balance");

    uint256 amountOfMaticFromUsd = convertUsdInMatic(msg.value);
    
    uint amountOfMaticRequired = (amount / shardsPerMatic) * (10 ** 18);
    require(amountOfMaticFromUsd >= amountOfMaticRequired, "Incorrect number of MATIC given for the wanted amount of shards");

    SafeERC20.safeTransfer(shard, msg.sender, amount);

    ownerMaticAmountToWithdraw += amountOfMaticRequired;

    emit BuyShardsInUsd(msg.sender, msg.value, amount);
  }

  /**
  * @notice Allow a user to buy ItemSkin paying with Shard
  */
  function buySkinGame(uint256 skinId, uint256 amount, uint256 skinPrice) public payable {
    uint256 amountOfShardsRequired = amount * skinPrice * (10 ** 18);
    require(msg.value == amountOfShardsRequired, "Not enough shards");

    uint256 vendorBalance = itemSkin.balanceOf(address(this));
    require(vendorBalance >= amount, "Vendor contract has not enough items in its balance");

    itemSkin.safeTransferFrom(address(this), msg.sender, skinId);

    ownerShardAmountToWithdraw += amountOfShardsRequired;

    emit BuyItemSkinInShard(msg.sender, msg.value, amount);
  }
  
  /**
  * @notice Allow the owner of the contract to withdraw MATIC
  */
  function maticWithdraw() public onlyOwner {
    require(ownerMaticAmountToWithdraw > 0, "Owner has not balance to withdraw");

    (bool sent,) = msg.sender.call{value: ownerMaticAmountToWithdraw}("");
    require(sent, "Failed to send user balance back to the owner");

    ownerMaticAmountToWithdraw = 0;
  }

  /**
  * @notice Allow the owner of the contract to withdraw Shard
  */
  function shardWithdraw() public onlyOwner {
    require(ownerShardAmountToWithdraw > 0, "Owner has not balance to withdraw");

    (bool sent,) = msg.sender.call{value: ownerShardAmountToWithdraw}("");
    require(sent, "Failed to send user balance back to the owner");

    ownerShardAmountToWithdraw = 0;
  }


}