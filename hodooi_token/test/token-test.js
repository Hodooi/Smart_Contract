const { expect } = require("chai");

describe("Token", function() {
    let token;

    beforeEach(async () => {
        const Token = await ethers.getContractFactory('HodooiToken');
        token = await Token.deploy();

        await token.deployed();
    });

    it("Should have a total supply", async function() {
        expect(await token.totalSupply()).to.equal('1000000000000000000000000000');
    });

    it("Gives owner balance", async function() {
        let [owner, signer1] = await ethers.getSigners();
        expect(await token.balanceOf(owner.address)).to.equal('1000000000000000000000000000');
        expect(await token.balanceOf(signer1.address)).to.equal(0);
    });

    it("Can transfer", async function() {
        let [owner, signer1] = await ethers.getSigners();
        expect(await token.transfer(signer1.address, 6500001)).to.not.be.empty;
        expect(await token.balanceOf(signer1.address)).to.equal(6500001);
    });

    it("Has correct info", async function() {
        let [owner, signer1] = await ethers.getSigners();
        expect(await token.symbol()).to.equal('HOD')
        expect(await token.name()).to.equal('Hodooi.com');
    });
});
