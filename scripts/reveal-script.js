const { ethers } = require("ethers");
const hre = require("hardhat");

//Revealing true URI

//run with this for testing: npx hardhat run scripts/reveal-script.js --network rinkeby 
// run with this for mainnet: npx hardhat run scripts/reveal-script.js --network mainnet
async function main() {

const contractAddress = process.env.PUBLIC_ADDRESS
const coffeeMonster = await (await hre.ethers.getContractFactory("CoffeeMonster")).attach(contractAddress)

await coffeeMonster.reveal();

}


const runMain = async () => {
  try {
      await main();
      process.exit(0);
  } catch (error) {
      console.log(error);
      process.exit(1);
  }
};


runMain();