import { ethers } from "hardhat";
const params = require("./arguments");

async function main() {
  // Deploying the RentalContract contract
  // const AXBContract = await ethers.getContractFactory("AiXBlock");
  // const AXB = await AXBContract.deploy();
  // await AXB.deployed();

  const RentalContract = await ethers.getContractFactory("RentalContract");
  const rentalContract = await RentalContract.deploy(params[0], params[1]);

  await rentalContract.deployed();
  // console.log("AXBContract deployed to:", AXB.address);
  console.log("RentalContract deployed to:", rentalContract.address);
  console.log(
    "npx hardhat verify --network mumbai --constructor-args scripts/arguments.ts " +
      rentalContract.address
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
