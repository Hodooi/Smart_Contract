const hodooiExchange = artifacts.require("HodooiExchange");

//    main net
//    const bnbRouter = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
//    const usdt = 0x55d398326f99059fF775485246999027B3197955;
//    const busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
//    const bnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

//    test net
const bnbRouter = 0x0000000000000000000000000000000000000000;
const usdt = 0x584119951fA66bf223312A29FB6EDEBdd957C5d8;
const busd = 0x1a0B0c776950e31b05FB25e3d7E14f99592bFB71;
const bnb = 0xD5513cbe97986e7D366B8979D887CB76e441b148;

module.exports = function(deployer) {
  deployer.deploy(hodooiExchange, bnbRouter, usdt, busd, bnb);
};

// testnet
//
// mainnet
//