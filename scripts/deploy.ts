import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const shardAmountToDeploy = 5000
  const DECIMALS = "8"
  const INITIAL_PRICE_ETH_USD = "162896000000"
  const INITIAL_PRICE_MATIC_USD = "55000000"

  console.log("Deploying contracts with the account: ", deployer.address);

  const shard = await ethers.deployContract("Shard", [shardAmountToDeploy])
  const shardAddress = await shard.getAddress()
  
  //Deploy these contracts only on development environment
  const mockV3Aggregator_ETH_USD = await ethers.deployContract("MockV3Aggregator", [DECIMALS, INITIAL_PRICE_ETH_USD]);
  const mockV3Aggregator_MATIC_USD = await ethers.deployContract("MockV3Aggregator", [DECIMALS, INITIAL_PRICE_MATIC_USD]);

  const aggregator_ETH_USD_address = await mockV3Aggregator_ETH_USD.getAddress();
  const aggregator_MATIC_USD_address = await mockV3Aggregator_MATIC_USD.getAddress();

  const priceConsumer_ETH_USD = await ethers.deployContract("PriceConsumerV3", [aggregator_ETH_USD_address])
  const priceConsumer_MATIC_USD = await ethers.deployContract("PriceConsumerV3", [aggregator_MATIC_USD_address])

  const priceConsumer_ETH_USD_address = await priceConsumer_ETH_USD.getAddress()
  const priceConsumer_MATIC_USD_address = await priceConsumer_MATIC_USD.getAddress()

  const market = await ethers.deployContract("Market", [shardAddress, priceConsumer_ETH_USD, priceConsumer_MATIC_USD_address])
  
  const marketAddress = await market.getAddress()

  console.log("Deployed contracts:")
  console.log("Shard address:", shardAddress, 
    "\nPriceConsumer_ETH_USD address:", priceConsumer_ETH_USD_address,
    "\nPriceConsumer_MATIC_USD address:", priceConsumer_MATIC_USD_address,
    "\nMarket address:", marketAddress)

  await shard.transfer(marketAddress, ethers.parseEther('4000'))
  console.log("Transfered some shards to Market")
  
  await market.transferOwnership(deployer.address)
  console.log("Transfered ownership of market to deployer", deployer.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
