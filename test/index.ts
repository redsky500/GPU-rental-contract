// eslint-disable-next-line node/no-missing-import
import { RentalContract__factory } from "typechain";
import { RentalContract } from "../typechain/RentalContract";

// test/RentalContract.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

// const tokenAddress = "0xaaaa";
// const priceFeedAddress = "0xbbbb";

describe("RentalContract", function () {
  let rentalContract: RentalContract;
  let owner: { address: string };
  let tokenAddress: { address: string };
  let priceFeedAddress: { address: string };

  this.beforeAll(async function () {
    [owner] = await ethers.getSigners();
    console.log(owner.address);
  });
  beforeEach(async function () {
    const rentalContractFactory = (await ethers.getContractFactory(
      "RentalContract",
      owner
    )) as RentalContract;
    rentalContract = await rentalContractFactory.deploy(
      tokenAddress,
      priceFeedAddress
    );

    await rentalContract.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner and addresses", async function () {
      expect(await rentalContract.owner()).to.equal(owner.address);
      expect(await rentalContract.token()).to.equal(tokenAddress);
      expect(await rentalContract.priceFeed()).to.equal(priceFeedAddress);
    });
  });

  describe("Rent Operations", function () {
    it("Should allow adding rental", async function () {
      await rentalContract.rentAdd(100, 0);
      const rental = await rentalContract.getRental(owner.address, 0);
      expect(rental.rentalPrice).to.equal(100);
    });

    it("Should allow modifying rental", async function () {
      await rentalContract.rentAdd(100, 0);
      await rentalContract.rentModify(0, 200);
      const rental = await rentalContract.getRental(owner.address, 0);
      expect(rental.rentalPrice).to.equal(200);
    });

    it("Should allow removing rental", async function () {
      await rentalContract.rentAdd(100, 0);
      await rentalContract.rentRemove(0);
      const rental = await rentalContract.getRental(owner.address, 0);
      expect(rental.isActive).to.equal(false);
    });

    it("Should allow starting rental", async function () {
      await rentalContract.rentAdd(100, 0);
      await rentalContract.startRental(owner.address, 0);
      const rental = await rentalContract.getRental(owner.address, 0);
      expect(rental.isActive).to.equal(true);
    });

    it("Should allow discontinuing rental", async function () {
      await rentalContract.rentAdd(100, 0);
      await rentalContract.startRental(owner.address, 0);
      await rentalContract.discontinueRental(owner.address, 0);
      const rental = await rentalContract.getRental(owner.address, 0);
      expect(rental.isActive).to.equal(false);
    });

    it("Should allow payout rental", async function () {
      await rentalContract.rentAdd(100, 0);
      await rentalContract.startRental(owner.address, 0);
      await rentalContract.discontinueRental(owner.address, 0);
      await rentalContract.payoutRental(owner.address, 0);
      const rental = await rentalContract.getRental(owner.address, 0);
      expect(rental.isActive).to.equal(false); // Rental should be inactive after payout
    });
  });
  
});

describe("AiXBlock Contract", function () {
  let aiXBlock;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    const AiXBlock = await ethers.getContractFactory("AiXBlock");
    aiXBlock = await AiXBlock.deploy();
    await aiXBlock.deployed();
  });

  it("Should set the right owner", async function () {
    expect(await aiXBlock.owner()).to.equal(owner.address);
  });

  it("Should mint tokens to allocations", async function () {
    await aiXBlock.releaseVestedTokens("Seed");
    await aiXBlock.releaseVestedTokens("Private");
    await aiXBlock.releaseVestedTokens("Strategic");
    await aiXBlock.releaseVestedTokens("Public");
    await aiXBlock.releaseVestedTokens("Team/Advisor");
    await aiXBlock.releaseVestedTokens("Rewards/Community");
    await aiXBlock.releaseVestedTokens("EcosystemGrowth");
    await aiXBlock.releaseVestedTokens("Reserves");

    const seedBalance = await aiXBlock.balances("Seed");
    const privateBalance = await aiXBlock.balances("Private");
    const strategicBalance = await aiXBlock.balances("Strategic");
    const publicBalance = await aiXBlock.balances("Public");
    const teamAdvisorBalance = await aiXBlock.balances("Team/Advisor");
    const rewardsCommunityBalance = await aiXBlock.balances("Rewards/Community");
    const ecosystemGrowthBalance = await aiXBlock.balances("EcosystemGrowth");
    const reservesBalance = await aiXBlock.balances("Reserves");

    expect(seedBalance).to.not.equal(0);
    expect(privateBalance).to.not.equal(0);
    expect(strategicBalance).to.not.equal(0);
    expect(publicBalance).to.not.equal(0);
    expect(teamAdvisorBalance).to.not.equal(0);
    expect(rewardsCommunityBalance).to.not.equal(0);
    expect(ecosystemGrowthBalance).to.not.equal(0);
    expect(reservesBalance).to.not.equal(0);
  });
});