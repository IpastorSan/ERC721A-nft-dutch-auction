const { ethers } = require("ethers");
const hre = require("hardhat");

//Setting baseURI and open sale

//run with this for testing: npx hardhat run scripts/opensale-script.js --network rinkeby 
//run with this for mainnet: npx hardhat run scripts/opensale-script.js --network mainnet
async function main() {

const contractAddress = process.env.PUBLIC_ADDRESS
const coffeeMonster = await(await hre.ethers.getContractFactory("CoffeeMonster")).attach(contractAddress)

const baseURI = process.env.BASE_URI;
await coffeeMonster.changeBaseURI(baseURI);

await coffeeMonster.openSale();

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
