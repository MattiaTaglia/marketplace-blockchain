import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
const { web3 } = require('@openzeppelin/test-helpers/src/setup');

const fromWei = (x: number) => web3.utils.fromWei(x.toString());
const toWei = (x: number) => web3.utils.toWei(x.toString());
const round2Decimals = (x: number | string) => Math.round((Number(x) + Number.EPSILON) * 100) / 100;

describe('Market', function() {
  async function deployMarket() {
    const [owner, otherAccount] = await ethers.getSigners();

    const shardAmount = 1000
    const DECIMALS = "8"
    const INITIAL_PRICE_ETH_USD = "162896000000"
    const INITIAL_PRICE_MATIC_USD = "55000000"

    const Shard = await ethers.getContractFactory("Shard");
    const shard = await Shard.deploy(shardAmount);

    const MockV3Aggregator = await ethers.getContractFactory("MockV3Aggregator");
    const mockV3Aggregator_ETH_USD = await MockV3Aggregator.deploy(DECIMALS, INITIAL_PRICE_ETH_USD);
    const mockV3Aggregator_MATIC_USD = await MockV3Aggregator.deploy(DECIMALS, INITIAL_PRICE_MATIC_USD);
    
    let priceFeedAddress_ETH_USD = await mockV3Aggregator_ETH_USD.getAddress()
    let priceFeedAddress_MATIC_USD = await mockV3Aggregator_MATIC_USD.getAddress()

    const PriceConsumerV3 = await ethers.getContractFactory("PriceConsumerV3")
    const priceConsumer_ETH_USD = await PriceConsumerV3.deploy(priceFeedAddress_ETH_USD)
    const priceConsumer_MATIC_USD = await PriceConsumerV3.deploy(priceFeedAddress_MATIC_USD)

    const ItemSkin = await ethers.getContractFactory("ItemSkin");
    const itemSkin = await ItemSkin.deploy();
    //await itemSkin.safeMint(owner, )

    const Market = await ethers.getContractFactory("Market");
    const market = await Market.deploy(await shard.getAddress(), await itemSkin.getAddress(), 
      await priceConsumer_ETH_USD.getAddress(), priceConsumer_MATIC_USD.getAddress())

    await shard.transfer(await market.getAddress(), ethers.parseEther('20'))
    await market.transferOwnership(owner.address)

    return { shard, itemSkin, priceConsumer_ETH_USD, priceConsumer_MATIC_USD, market, shardAmount, owner, otherAccount }
  }

  describe("Deployment", function() {
    it("Check if shard contract is deployed correctly", async function() {
      const { shard } = await loadFixture(deployMarket);
      
      expect(await shard.getAddress()).to.match(/0x[0-9a-fA-F]{40}/);
    })

    it("Check if itemSkin contract is deployed correctly", async function() {
      const { itemSkin } = await loadFixture(deployMarket);
      
      expect(await itemSkin.getAddress()).to.match(/0x[0-9a-fA-F]{40}/);
    })

    it("Check if market contract is deployed correctly", async function() {
      const { market } = await loadFixture(deployMarket);
      
      expect(await market.getAddress()).to.match(/0x[0-9a-fA-F]{40}/);
    })
  })

  describe("Conversion of Tokens", function() {
    it("Get conversion ETH/USD", async function() {
      const { priceConsumer_ETH_USD, market } = await loadFixture(deployMarket);

      const ethValue = 0.0010
      const usdValue = 2000

      const price = await priceConsumer_ETH_USD.getLatestPrice();
      console.log("Price from oracle is: ", BigInt(price).toString());
      
      const convertedPrice = await market.convertEthInUsd(toWei(ethValue));
      console.log(ethValue, " ETH is: ", round2Decimals(fromWei(Number(convertedPrice) / 10 ** 8)), " USD")

      const convertedUsd = await market.convertUsdInEth(usdValue);
      console.log(usdValue, " USD are: ",  round2Decimals(fromWei(Number(convertedUsd))), " ETH")
    })

    it("Get conversion MATIC/USD", async function() {
      const { priceConsumer_MATIC_USD, market } = await loadFixture(deployMarket);
      
      const maticValue = 0.5
      const usdValue = 2

      const price = await priceConsumer_MATIC_USD.getLatestPrice();
      console.log("MATIC oracle price is: ", BigInt(price).toString());
      
      const convertedPrice = await market.convertMaticInUsd(toWei(maticValue));
      console.log(maticValue, " MATIC is: ", round2Decimals(fromWei(Number(convertedPrice) / 10 ** 8)), " USD")
  
      const convertedUsd = await market.convertUsdInMatic(usdValue);
      console.log(usdValue, " USD are: ",  round2Decimals(fromWei(Number(convertedUsd))), " MATIC")
    })

    it("Get conversion ETH/MATIC", async function() {
      const { market } = await loadFixture(deployMarket);
  
      const ethValue = 0.0010

      const convertedEthUsd = await market.convertEthInUsd(toWei(ethValue));
      console.log(ethValue, " ETH are: ", round2Decimals(fromWei(Number(convertedEthUsd) / 10 ** 8)), " USD")

      const convertedUsdMatic = await market.convertUsdInMatic(convertedEthUsd);
      console.log(round2Decimals(fromWei(Number(convertedEthUsd) / 10 ** 8)), " USD are: ",  
        round2Decimals(fromWei(Number(convertedUsdMatic) / 10 ** 26)), " MATIC")
    })
  })

  describe("Acquisitions of Shards", function() {
    it("Buy some shards with MATIC", async function() {
      const { shard, market, owner, otherAccount } = await loadFixture(deployMarket);
      
      const amountToBuy = 100
      const amountOfMatic = ethers.parseEther('2')
      await expect(
        market.connect(otherAccount).buyShardsInMatic(amountToBuy, {
          value: amountOfMatic
        })
      )
      .to.emit(market, 'BuyShardsInMatic')
      .withArgs(otherAccount.address, amountOfMatic, amountToBuy)
    })

    it("Buy some shards with USD", async function() {
      const { shard, market, owner, otherAccount } = await loadFixture(deployMarket);
      
      const amountToBuy = 100
      const amountOfUSD = 2
      await expect(
        market.connect(otherAccount).buyShardsInUsd(amountToBuy, {
          value: amountOfUSD
        })
      )
      .to.emit(market, 'BuyShardsInUsd')
      .withArgs(otherAccount.address, amountOfUSD, amountToBuy)
    })

    it("Buy some shards with ETH", async function() {
      const { shard, market, owner, otherAccount } = await loadFixture(deployMarket);
      
      const amountToBuy = 100
      const amountOfEth = ethers.parseEther('0.0010')
      
      await expect(
        market.connect(otherAccount).buyShardsInEth(amountToBuy, {
          value: amountOfEth
        })
      )
      .to.emit(market, 'BuyShardsInEth')
      .withArgs(otherAccount.address, amountOfEth, amountToBuy)
    })

    it("Buy some shards with ETH (insufficient amount)", async function() {
      const { shard, market, owner, otherAccount } = await loadFixture(deployMarket);
      
      const amountToBuy = 100
      const amountOfEth = ethers.parseEther('0.00010')
      
      await expect(
        market.connect(otherAccount).buyShardsInEth(amountToBuy, {
          value: amountOfEth
        })
      )
      .to.be.revertedWith("Incorrect number of MATIC given for the wanted amount of shards")
    })
  })

/*   describe("Acquisitions of ItemSkin", function() {
    it("Buy an itemSkin with Shard", async function() {
      const { shard, itemSkin, market, owner, otherAccount } = await loadFixture(deployMarket);
      
      const amountToBuy = 1
      const amountOfShard = ethers.parseEther('100')
      await expect(
        market.connect(otherAccount).buySkinGame(2, amountToBuy, 100, {
          value: amountOfShard
        })
      )
      .to.emit(market, 'BuyItemSkinInShard')
      .withArgs(otherAccount.address, amountOfShard, amountToBuy)
    })
   
  }) */


  describe("Whitdraw of MATIC", function() {
    it("Withdraw some MATIC", async function() {
      const { shard, market, owner, otherAccount } = await loadFixture(deployMarket);
      
      const maticOfShardToBuy = ethers.parseEther('2');

      await market.connect(otherAccount).buyShardsInMatic(100, {
        value: maticOfShardToBuy
      })

      const txWithdraw = await market.connect(owner).maticWithdraw();

      const marketBalance = await ethers.provider.getBalance(await market.getAddress())
      expect(marketBalance).to.equal(0)

      await expect(txWithdraw).to.changeEtherBalance(owner, maticOfShardToBuy)
    })
  })
})