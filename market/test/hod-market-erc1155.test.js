const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } =  require("ethers");
const { web3 } = require("openzeppelin-test-helpers/src/setup");
const constants = require("openzeppelin-test-helpers/src/constants");
const { ZERO_ADDRESS } = require("openzeppelin-test-helpers/src/constants");
const big = (n) => web3.utils.toBN(n);

function expandTo18Decimals(n) {
  return BigNumber.from(n).mul(BigNumber.from(10).pow(18));
}

describe("Token contract", () => {
  let HodooiMarket,
    hodooiMarket,
    NFT1155,
    nft1155,
    owner,
    addr1,
    addr2,
    addr3,
    UsdtToken,
    usdtToken,
    WBnbToken,
    wBnb,
    balanceNFTOfMarket,
    defaultBalance;

  beforeEach(async () => {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    console.log(`======== List accounts ======`);
    console.log(`=== owner: ${owner.address}, addr1: ${addr1.address}, add2: ${addr2.address}`);

    //market
    HodooiMarket = await ethers.getContractFactory("HodooiMarket");
    hodooiMarket = await HodooiMarket.deploy(
      "0x2CA0ff08FBF7A56f43f2FB3D3B9717B4fff9673d",
      1
    );

    //NFT
    NFT1155 = await ethers.getContractFactory("MockERC1155");
    nft1155 = await NFT1155.deploy();
    console.log("nft1155: ", nft1155.address);

    //payment
    UsdtToken = await ethers.getContractFactory("MockUSDTNative");
    usdtToken = await UsdtToken.deploy();
    WBnbToken = await ethers.getContractFactory("MockWBNB");
    wBnb = await WBnbToken.deploy();

    // Exchange
    HodooiExchange = await ethers.getContractFactory("MockHodExchange");
    hodooiExchange = await HodooiExchange.deploy();

    //Referral
    HodooiReferral = await ethers.getContractFactory("HodooiReferral");
    hodooiReferral = await HodooiReferral.deploy(owner.address);

    //add config
    hodooiMarket.setWhiteListPayableToken(usdtToken.address, 1);
    hodooiMarket.setWhiteListPayableToken(wBnb.address, 1);
    hodooiMarket.setExchangeContract(hodooiExchange.address);
    hodooiMarket.setReferralContract(hodooiReferral.address);
  
    console.log(`======== List contract address ======`);
    console.log(
      `=== market: ${hodooiMarket.address}, exchange: ${hodooiExchange.address}, nft1155: ${hodooiExchange.address}, referral: ${hodooiReferral}`
    );
    console.log(`=== USDT: ${usdtToken.address}, wBnb: ${wBnb.address}`);
  
  });

  describe("Test create erc1155 and put on sale", async () => {
    it("Should properly create NFT and put on sale/buy success", async () => {

      //Init
      defaultBalance = web3.utils.toWei("10000", "ether");
      await usdtToken.connect(addr1).mint(defaultBalance);
      await usdtToken.connect(addr1).approve(hodooiMarket.address, defaultBalance);
      // expect(await usdtToken.balanceOf(addr1.address)).to.equal(defaultBalance);
      // expect(await usdtToken.allowance(addr1.address, hodooiMarket.address)).to.equal(defaultBalance);

      console.log(`======== List contract address ======`);
      console.log(
        `=== market: ${hodooiMarket.address}, exchange: ${hodooiExchange.address}, nft1155: ${hodooiExchange.address}, referral: ${hodooiReferral}`
      );
      console.log(`=== USDT: ${usdtToken.address}, wBnb: ${wBnb.address}`);
    
      // Account's balance
      console.log(`===== [Init] Account's balance:`);
      console.log("=== Owner's balance: ", (await usdtToken.balanceOf(owner.address)).toString());
      console.log("=== Address1's balance: ", (await usdtToken.balanceOf(addr1.address)).toString());
      console.log("=== Address2's balance: ", (await usdtToken.balanceOf(hodooiMarket.address)).toString());

      //***Create NFTs
      //_maxSupply: 50
      // _initialSupply: 50
      // _loyaltyFee: 1000 ~ 10% 0.1
      await nft1155.create(50, 50, 1000, "/nft/1633675915072.json", "0x", {
        from: owner.address,
      });

      expect(await nft1155._currentTokenID()).to.equal(1);

      // setApprovalForAll
      await nft1155.setApprovalForAll(hodooiMarket.address, 1, {
        from: owner.address,
      });
      let isApprovedForAll = await nft1155.isApprovedForAll(
        owner.address,
        hodooiMarket.address
      );
      expect(isApprovedForAll).to.equal(true);

      //list
      // order: { quantity = 10, price = 2 usdt }
      let tokenId = 1;
      let quantity = 10;
      let mask = 1; // put on sale
      let expiration = 0; //infinity
      let itemPrice = web3.utils.toWei("20", "ether"); //2*10
      await hodooiMarket.list(
        nft1155.address,
        tokenId,
        quantity,
        mask,
        itemPrice,
        usdtToken.address,
        expiration
      );

      balanceNFTOfMarket = await nft1155.balanceOf(hodooiMarket.address, 1);
      // validator order

      let order = await hodooiMarket.items(0);
      expect(order.price).to.be.eq(itemPrice);
      expect(order.mask).to.be.eq(1);
      expect(order.quantity).to.be.eq(10);
      expect(parseInt(balanceNFTOfMarket.toString())).to.be.eq(10);
      
      //Buy with itemId = 0, quanity = 1
      let paymentAmount = web3.utils.toWei("2.05", "ether");
      await hodooiMarket
        .connect(addr1)
        .buy(0, 1, usdtToken.address, paymentAmount);

      // Address1's balance after list NFT
      let balanceNFTOfAddress1 = await nft1155.balanceOf(addr1.address, 1);
      expect(balanceNFTOfAddress1).to.equal(1);

      console.log(`===== [List] Account's balance after buy nft`);
      console.log("=== Owner's balance: ", (await usdtToken.balanceOf(owner.address)).toString());
      console.log("=== Buyer's balance: ", (await usdtToken.balanceOf(addr1.address)).toString());
      console.log("=== Market's balance: ", (await usdtToken.balanceOf(hodooiMarket.address)).toString());
      
    });
  });

  describe("Test create erc1155 and put on sale", async () => {
    it("Should properly create NFT and put on sale/buy success", async () => {

      //Init
      let tokenId = 1;
      let quantity = 10;
      let mask = 1; // put on sale
      let expiration = 0; //infinity
      let itemPrice, order, balanceNFTOfAddress1, balanceNFTOfAddress2, balanceNFTOfAddress3, paymentAmount;
      defaultBalance1 = web3.utils.toWei("71.57992", "ether");
      defaultBalance2 = web3.utils.toWei("130.91506", "ether");
      defaultBalance3 = web3.utils.toWei("91.65", "ether");
      
      await usdtToken.connect(addr1).mint(defaultBalance1);
      await usdtToken.connect(addr1).approve(hodooiMarket.address, defaultBalance1);
      expect(await usdtToken.allowance(addr1.address, hodooiMarket.address)).to.equal(defaultBalance1);
    
      await usdtToken.connect(addr2).mint(defaultBalance2);
      await usdtToken.connect(addr2).approve(hodooiMarket.address, defaultBalance2);
      expect(await usdtToken.allowance(addr2.address, hodooiMarket.address)).to.equal(defaultBalance2);

      await usdtToken.connect(addr3).mint(defaultBalance3);
      await usdtToken.connect(addr3).approve(hodooiMarket.address, defaultBalance3);
      expect(await usdtToken.allowance(addr3.address, hodooiMarket.address)).to.equal(defaultBalance3);

      // Account's balance
      console.log(`===== [Init] Account's balance:`);
      console.log("=== Address1's balance: ", (await usdtToken.balanceOf(addr1.address)).toString());
      console.log("=== Address2's balance: ", (await usdtToken.balanceOf(addr2.address)).toString());
      console.log("=== Address3's balance: ", (await usdtToken.balanceOf(addr3.address)).toString());

      //====================== CASE 1====================//
      //***Create NFTs
      //_maxSupply: 50
      // _initialSupply: 50
      // _loyaltyFee: 1000 ~ 10% 0.1
      await nft1155.connect(addr1).create(50, 50, 1000, "/nft/1633675915072.json", "0x");

      expect(await nft1155._currentTokenID()).to.equal(1);

      // setApprovalForAll
      await nft1155.connect(addr1).setApprovalForAll(hodooiMarket.address, 1);
      let isApprovedForAll = await nft1155.isApprovedForAll(
        addr1.address,
        hodooiMarket.address
      );
      expect(isApprovedForAll).to.equal(true);

      //list
      itemPrice = web3.utils.toWei("20", "ether"); // price * quantity = 2*10
      await hodooiMarket.connect(addr1).list(
        nft1155.address,
        tokenId,
        quantity,
        mask,
        itemPrice,
        usdtToken.address,
        expiration
      );

      balanceNFTOfMarket = await nft1155.balanceOf(hodooiMarket.address, 1);
      // validator order

      order = await hodooiMarket.items(0);
      expect(order.price).to.be.eq(itemPrice);
      expect(order.mask).to.be.eq(1);
      expect(order.quantity).to.be.eq(10);
      expect(parseInt(balanceNFTOfMarket.toString())).to.be.eq(10);
      
      //Buy with itemId = 0, quanity = 1
      paymentAmount = web3.utils.toWei("2.05", "ether");
      await hodooiMarket
        .connect(addr2)
        .buy(0, 1, usdtToken.address, paymentAmount);

      // Address1's balance after list NFT
      balanceNFTOfAddress2 = await nft1155.balanceOf(addr2.address, 1);
      expect(balanceNFTOfAddress2).to.equal(1);

      console.log(`===== [List] Account's balance after turn 1`);
      console.log("=== Address1's balance: ", (await usdtToken.balanceOf(addr1.address)).toString());
      console.log("=== Address2's balance: ", (await usdtToken.balanceOf(addr2.address)).toString());
      console.log("=== Address3's balance: ", (await usdtToken.balanceOf(addr3.address)).toString());

      //====================== CASE 2====================//

      // setApprovalForAll
      await nft1155.connect(addr2).setApprovalForAll(hodooiMarket.address, 1);
      isApprovedForAll = await nft1155.isApprovedForAll(
        addr2.address,
        hodooiMarket.address
      );
      expect(isApprovedForAll).to.equal(true);

      //list
      quantity = 1;
      itemPrice = web3.utils.toWei("3", "ether"); // price* quantity = 3*1
      await hodooiMarket.connect(addr2).list(
        nft1155.address,
        tokenId,
        quantity,
        mask,
        itemPrice,
        usdtToken.address,
        expiration
      );
      
      balanceNFTOfMarket = await nft1155.balanceOf(hodooiMarket.address, 1);
      expect(parseInt(balanceNFTOfMarket.toString())).to.be.eq(10);
       
      order = await hodooiMarket.items(1);
      expect(order.price).to.be.eq(itemPrice);
      expect(order.mask).to.be.eq(1);
      expect(order.quantity).to.be.eq(1);

      //Buy with itemId = 0, quanity = 1
      paymentAmount = web3.utils.toWei("3.075", "ether");
      await hodooiMarket
        .connect(addr3)
        .buy(1, 1, usdtToken.address, paymentAmount);

      // Address1's balance after list NFT
      balanceNFTOfAddress2 = await nft1155.balanceOf(addr3.address, 1);
      expect(balanceNFTOfAddress2).to.equal(1);

      console.log(`===== [List] Account's balance after turn 2`);
      console.log("=== Address1's balance: ", (await usdtToken.balanceOf(addr1.address)).toString());
      console.log("=== Address2's balance: ", (await usdtToken.balanceOf(addr2.address)).toString());
      console.log("=== Address3's balance: ", (await usdtToken.balanceOf(addr3.address)).toString());
      
    });
  });

});
