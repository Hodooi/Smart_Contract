const hodooiMarket = artifacts.require("HodooiMarket");

const scMarketAddress = "";
const scReferralAddress = "";
module.exports = function(deployer) {
  deployer.then(() => {
    return hodooiMarket.at(scMarketAddress);
  }).then((instance) => {
    return instance.setReferralContract(scReferralAddress);
  });
};