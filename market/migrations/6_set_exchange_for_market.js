const hodooiMarket = artifacts.require("HodooiMarket");

const scMarketAddress = "";
const scExchangeAddress = "";
module.exports = function(deployer) {
  deployer.then(() => {
    return hodooiMarket.at(scMarketAddress);
  }).then((instance) => {
    return instance.setSotaExchangeContract(scExchangeAddress);
  });
};
