const hre = require("hardhat");

async function main() {

//run with this for testing: npx hardhat run scripts/deploy-script.js --network rinkeby 
//run with this for mainnet: npx hardhat run scripts/deploy-script.js --network mainnet

// We get the contract to deploy
  const CoffeeMonsterContract = await hre.ethers.getContractFactory("CoffeeMonster");
  const CoffeeMonster = await CoffeeMonsterContract.deploy();

  await CoffeeMonster.deployed();

  console.log("CoffeeMonster deployed to:", CoffeeMonster.address);
  console.log(`See collection in Rarible:  https://rinkeby.rarible.com/token/${CoffeeMonster.address}`)
  console.log(`See collection in Opensea: https://testnets.opensea.io/${CoffeeMonster.address}`)
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
