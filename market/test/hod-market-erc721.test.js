const { ethers } = require("hardhat");

const { BigNumber } =  require("ethers");

const HodooiMarket = artifacts.require("HodooiMarket");
const MockUSDT = artifacts.require("MockUSDT");
//const MockSOTA = artifacts.require("MockSOTA");
const MockWBNB = artifacts.require("MockWBNB");
const HodooiExchange = artifacts.require("MockHodExchange");
const HodooiReferral = artifacts.require("HodooiReferral");
const MockERC721 = artifacts.require("MockERC721");

const { expect } = require("chai"); 
const constants = require("openzeppelin-test-helpers/src/constants");
const { ZERO_ADDRESS } = require("openzeppelin-test-helpers/src/constants");
const { web3 } = require("openzeppelin-test-helpers/src/setup");

const big = (n) => web3.utils.toBN(n);

function expandTo18Decimals(n) {
  return BigNumber.from(n).mul(BigNumber.from(10).pow(18));
}

const oldMarket = "0x2CA0ff08FBF7A56f43f2FB3D3B9717B4fff9673d";
const limitAuction = 1;

const deployMock = async (owner, wallet1, wallet2, wallet3) => {
  const hodooiMarket = await HodooiMarket.new(oldMarket, limitAuction, {from: owner});
  const hodooiExchange = await HodooiExchange.new()
  const hodooiReferral = await HodooiReferral.new(owner)
  const hodooiERC721 = await MockERC721.new();
  const hodooiWBNB = await MockWBNB.new();
  const hodooiUSDT = await MockUSDT.new(owner, expandTo18Decimals(100));

  // CONFIGURE MARKET
  const marketFee = 250;
  const firstSellFee = 250;
  const artistLoyaltyFee = 5000;
  const referralFee = 5000;

  await hodooiMarket.setWhiteListPayableToken(hodooiUSDT.address, 1, {from: owner});
  await hodooiMarket.setWhiteListPayableToken(hodooiWBNB.address, 1, {from: owner});
  await hodooiMarket.setExchangeContract(hodooiExchange.address);
  await hodooiMarket.setReferralContract(hodooiReferral.address);
  await hodooiMarket.setSystemFee(marketFee,  firstSellFee,  artistLoyaltyFee,  referralFee);

  let defaultBalance = expandTo18Decimals(100);
  await hodooiUSDT.mint(wallet1, defaultBalance, {from: wallet1});
  await hodooiUSDT.approve(hodooiMarket.address, defaultBalance, {from: wallet1});

  await hodooiUSDT.mint(wallet2, defaultBalance, {from: wallet2});
  await hodooiUSDT.approve(hodooiMarket.address, defaultBalance, {from: wallet2});

  await hodooiUSDT.mint(wallet3, defaultBalance, {from: wallet3});
  await hodooiUSDT.approve(hodooiMarket.address, defaultBalance, {from: wallet3});

  //let tien = await hodooiUSDT.balanceOf(wallet1);
  //console.log(web3.utils.fromWei(tien.toString(), "ether"));

  //console.log(hodooiUSDT.address);
  //console.log(bol.receipt.status);
  // web3.fromWei(balance.toNumber(), "ether" )

  return {
    hodooiMarket,
    hodooiExchange,
    hodooiReferral,
    hodooiERC721,
    hodooiWBNB,
    hodooiUSDT
  };
};

const deployMock_New = async (owner, wallet1, wallet2, wallet3, oldMarket, limitAuction) => {
  const hodooiMarketNew = await HodooiMarket.new(oldMarket, limitAuction, {from: owner});
  const hodooiExchangeNew = await HodooiExchange.new()
  const hodooiReferralNew = await HodooiReferral.new(owner)
  const hodooiERC721New = await MockERC721.new();
  const hodooiWBNBNew = await MockWBNB.new();
  const hodooiUSDTNew = await MockUSDT.new(owner, expandTo18Decimals(100));

  // CONFIGURE MARKET
  const marketFeeNew = 250;
  const firstSellFeeNew = 250;
  const artistLoyaltyFeeNew = 5000;
  const referralFeeNew = 5000;

  await hodooiMarketNew.setWhiteListPayableToken(hodooiUSDTNew.address, 1, {from: owner});
  await hodooiMarketNew.setWhiteListPayableToken(hodooiWBNBNew.address, 1, {from: owner});
  await hodooiMarketNew.setExchangeContract(hodooiExchangeNew.address);
  await hodooiMarketNew.setReferralContract(hodooiReferralNew.address);
  await hodooiMarketNew.setSystemFee(marketFeeNew,  firstSellFeeNew,  artistLoyaltyFeeNew,  referralFeeNew);

  let defaultBalanceNew = expandTo18Decimals(100);
  await hodooiUSDTNew.mint(wallet1, defaultBalanceNew, {from: wallet1});
  await hodooiUSDTNew.approve(hodooiMarketNew.address, defaultBalanceNew, {from: wallet1});

  await hodooiUSDTNew.mint(wallet2, defaultBalanceNew, {from: wallet2});
  await hodooiUSDTNew.approve(hodooiMarketNew.address, defaultBalanceNew, {from: wallet2});

  await hodooiUSDTNew.mint(wallet3, defaultBalanceNew, {from: wallet3});
  await hodooiUSDTNew.approve(hodooiMarketNew.address, defaultBalanceNew, {from: wallet3});

  return {
    hodooiMarketNew,
    hodooiExchangeNew,
    hodooiReferralNew,
    hodooiERC721New,
    hodooiWBNBNew,
    hodooiUSDTNew
  };
};

contract("Hodooi Market", ([owner, wallet1, wallet2, wallet3, wallet4]) => {

  it("should properly initialize the contract", async () => {
    const {
      hodooiMarket,
      hodooiERC721,
      hodooiWBNB,
      hodooiUSDT
    } = await deployMock(owner, wallet1, wallet2, wallet3);

    const check = await hodooiMarket.limitAuction();
    //console.log(web3.utils.fromWei(check.toNumber(), "ether" ));
    expect(check.words[0]).to.be.eq(1);
  });
  
  it("NFT ERC-721 --- PutOnSale and Buy/Sell ----", async () => {
    const {
      hodooiMarket,
      hodooiERC721,
      hodooiUSDT
    } = await deployMock(owner, wallet1, wallet2, wallet3);

    await hodooiERC721.create("abc", 1000, { from: owner });
    await hodooiERC721.setApprovalForAll(hodooiMarket.address, true, { from: owner });
    let balanceNFTOFSeller = await hodooiERC721.balanceOf(owner);
    console.log("Balance of seller: ", balanceNFTOFSeller.toString());
    let isApprovedForAll = await hodooiERC721.isApprovedForAll(
      owner,
      hodooiMarket.address
    );
    //let price = web3.utils.toWei("50", "ether");
    console.log("isApprovedForAll: ", isApprovedForAll);
    expect(isApprovedForAll).to.equal(true);

    let price = expandTo18Decimals(4);
    let tokenId = 1;
    let quantity = 1;
    let mask = 1;
    let expiration = 0; 
    await hodooiMarket.list(
      hodooiERC721.address, 
      tokenId, 
      quantity, 
      mask, 
      price,
      hodooiUSDT.address, 
      expiration, 
      { from: owner }
    );

    let balanceNFTOFMarket = await hodooiERC721.balanceOf(hodooiMarket.address);
    let order = await hodooiMarket.items(0);
    
    //console.log(web3.utils.fromWei(order.price.toString(), "ether"));
    expect(web3.utils.fromWei(order.price.toString(), "ether")).to.be.eq('4');
    expect(parseInt(order.mask.toString())).to.be.eq(1);
    expect(parseInt(order.quantity.toString())).to.be.eq(1);
    expect(parseInt(balanceNFTOFMarket.toString())).to.be.eq(1);
    
    let balanceOfOwner = await hodooiUSDT.balanceOf(owner);
    let balanceOfBuyer = await hodooiUSDT.balanceOf(wallet1);
    let balanceOfBuyer2 = await hodooiUSDT.balanceOf(wallet2);
    let balanceOfMarket = await hodooiUSDT.balanceOf(hodooiMarket.address);

    console.log("=== Account's balance after list NFT ===");
    console.log("Owner's balance: ", web3.utils.fromWei(balanceOfOwner.toString(), "ether")); 
    console.log("Buyer_1's balance: ", web3.utils.fromWei(balanceOfBuyer.toString(), "ether")); 
    console.log("Buyer_2's balance: ", web3.utils.fromWei(balanceOfBuyer2.toString(), "ether")); 
    console.log("Market's balance: ", web3.utils.fromWei(balanceOfMarket.toString(), "ether")); 


    let paymentAmount = expandTo18Decimals(10);
    await hodooiMarket.buy(0, 1, hodooiUSDT.address, paymentAmount, {from: wallet1});

    let balanceOfOwnerAfter = await hodooiUSDT.balanceOf(owner);
    let balanceOfBuyerAfter = await hodooiUSDT.balanceOf(wallet1);
    let balanceOfMarketAfter = await hodooiUSDT.balanceOf(hodooiMarket.address);

    console.log("=== Account's balance after buy/sell NFT Case 1 ===");
    console.log("Owner's balance: ", web3.utils.fromWei(balanceOfOwnerAfter.toString(), "ether")); 
    console.log("Buyer_1's balance: ", web3.utils.fromWei(balanceOfBuyerAfter.toString(), "ether"));
    console.log("Buyer_2's balance: ", web3.utils.fromWei(balanceOfBuyer2.toString(), "ether")); 
    console.log("Market's balance: ", web3.utils.fromWei(balanceOfMarketAfter.toString(), "ether")); 

    // Wallet1's balance after list Buy NFT
    let balanceNFTOfWallet1 = await hodooiERC721.balanceOf(wallet1, {from: wallet1});
    expect(parseInt(balanceNFTOfWallet1.toString())).to.equal(1);


    //====================== CASE 2====================//

    
    await hodooiERC721.setApprovalForAll(hodooiMarket.address, 1, {from: wallet1});
    let isApprovedForAllWallet1 = await hodooiERC721.isApprovedForAll(wallet1, hodooiMarket.address, {from: wallet1});
    expect(isApprovedForAllWallet1).to.equal(true);


    let priceSecondSell = expandTo18Decimals(6);
    await hodooiMarket.list(
      hodooiERC721.address, 
      tokenId, 
      quantity, 
      mask, 
      priceSecondSell,
      hodooiUSDT.address, 
      expiration, 
      { from: wallet1 }
    );

    let balanceNFTOfMarketSecondTime = await hodooiERC721.balanceOf(hodooiMarket.address, {from: wallet1});
    let ordersecond = await hodooiMarket.items(1);

    expect(web3.utils.fromWei(ordersecond.price.toString(), "ether")).to.be.eq('6');
    expect(parseInt(ordersecond.mask.toString())).to.be.eq(1);
    expect(parseInt(ordersecond.quantity.toString())).to.be.eq(1);
    expect(parseInt(balanceNFTOfMarketSecondTime.toString())).to.be.eq(1);

    let paymentAmountSecondSell = expandTo18Decimals(10);
    await hodooiMarket.buy(1, 1, hodooiUSDT.address, paymentAmountSecondSell, {from: wallet2});

    // Wallet1's balance after list Buy NFT
    let balanceNFTOfWallet2 = await hodooiERC721.balanceOf(wallet2, {from: wallet2});
    expect(parseInt(balanceNFTOfWallet2.toString())).to.equal(1);

    let balanceOfOwnerAfterSecondSell = await hodooiUSDT.balanceOf(owner);
    let balanceOfBuyerAfterSecondSell = await hodooiUSDT.balanceOf(wallet1);
    let balanceOfBuyer2AfterSecondSell = await hodooiUSDT.balanceOf(wallet2);
    let balanceOfMarketAfterSecondSell = await hodooiUSDT.balanceOf(hodooiMarket.address);

    console.log("=== Account's balance after buy/sell NFT Case 2 ===");
    console.log("Owner's balance: ", web3.utils.fromWei(balanceOfOwnerAfterSecondSell.toString(), "ether")); 
    console.log("Buyer_1's balance: ", web3.utils.fromWei(balanceOfBuyerAfterSecondSell.toString(), "ether"));
    console.log("Buyer_2's balance: ", web3.utils.fromWei(balanceOfBuyer2AfterSecondSell.toString(), "ether")); 
    console.log("Market's balance: ", web3.utils.fromWei(balanceOfMarketAfterSecondSell.toString(), "ether")); 

  });


  it("Should Migrates", async () => {
    const {
      hodooiMarket,
      hodooiERC721,
      hodooiWBNB,
      hodooiUSDT
    } = await deployMock(owner, wallet1, wallet2, wallet3);

    await hodooiERC721.create("abc", 1000, { from: owner });
    await hodooiERC721.create("abcd", 1000, { from: owner });

    await hodooiERC721.setApprovalForAll(hodooiMarket.address, true, { from: owner });
    let balanceNFTOFSeller = await hodooiERC721.balanceOf(owner);
    console.log("Balance of seller: ", balanceNFTOFSeller.toString());
    let isApprovedForAll = await hodooiERC721.isApprovedForAll(
      owner,
      hodooiMarket.address
    );

    console.log("isApprovedForAll: ", isApprovedForAll);
    expect(isApprovedForAll).to.equal(true);

    let price = expandTo18Decimals(2);
    let tokenId = 1;
    let quantity = 1;
    let mask = 1;
    let expiration = 0; 
    await hodooiMarket.list(
      hodooiERC721.address, 
      tokenId, 
      quantity, 
      mask, 
      price,
      hodooiUSDT.address, 
      expiration, 
      { from: owner }
    );
    await hodooiMarket.list(
      hodooiERC721.address, 
      2, 
      quantity, 
      mask, 
      price,
      hodooiUSDT.address, 
      expiration, 
      { from: owner }
    );

    let balanceNFTOFMarket = await hodooiERC721.balanceOf(hodooiMarket.address);
    expect(parseInt(balanceNFTOFMarket.toString())).to.be.eq(2);
    
    // ------------------

    const {
      hodooiMarketNew,
      hodooiERC721New,
      hodooiWBNBNew,
      hodooiUSDTNew
    } = await deployMock_New(owner, wallet1, wallet2, wallet3, hodooiMarket.address, 1);


    console.log("owner address:" , owner);
    console.log("Market Old address: ", hodooiMarket.address)
    console.log("Market New address: ", hodooiMarketNew.address)

    await hodooiMarketNew.adminMigrateData(0, 1);

    let balanceNFTOFMarketNew = await hodooiERC721.balanceOf(hodooiMarketNew.address);
    expect(parseInt(hodooiMarketNew.toString())).to.be.eq(2);
  });


});