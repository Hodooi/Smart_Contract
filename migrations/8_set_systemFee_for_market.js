const hodooiMarket = artifacts.require("HodooiMarket");

const scMarketAddress = "";
const marketFee = 0;
const firstSellFee = 0;
const artistLoyaltyFee = 0;
const referralFee = 0;
module.exports = function(deployer) {
  deployer.then(() => {
    return hodooiMarket.at(scMarketAddress);
  }).then((instance) => {
    return instance.setSystemFee(marketFee,  firstSellFee,  artistLoyaltyFee,  referralFee);
  });
};