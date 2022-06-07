# ERC721A with EIP-2981 Royalties and Dutch auction selling.
ERC721A NFT contract for a 10k pfp project with 3 minting phases based on time.

- Phase 1: The minting is open and the price starts at 1.05ETH. Then it drops by 0.5 ETH every 30 mins (using block.timestamp, so not totally exact, but close enough) for 8 hours or until the maximum amount of tokens for phase 1 is reached.
- Phase 2: The minting price drops to 85% of the last price of Phase 1 for 8 additional hours (minimum 0.3ETH, more if the tokens run out earlier).
- Phase 3: The minting price drops to 50% of the last price of Phase 1 for 24 additional hours.

I chose the ERC721A implementation to try out how its batch minting capabilities affects gas costs on miniting. To see a full comparison between OpenZeppelin`s ERC721 and ERC721A, see my other [repo](https://github.com/IpastorSan/ERC721vsERC1155vsERC721A-minting-gas-costs-comparison) 

Other features:
- EIP-2981 royalties. Set to send 5% of sales proceeds to the deployer of the contract. Note that even if I am using (owner()) in the constructor, this is a piece of information that needs to be overwritten calling ````setRoyalties```` if the contract change Owner. The logic for the Royalties is outside of the contract and the NFT contract inherits from the implementation.
- ````openPublicSale()```` to grant the deployer more control on the minting process, it needs to be called for the minting to happen.
- Max-tokens-per-wallet and max-tokens-per-mint. Avoid that any single wallet hoards all your collection. This can be bypassed spunning new wallets, but its annoying and the minter has to pay gas fees repeatedly.
- `````CallerIsUser```` modifier to only allow calls from EOA, not from other smart contracts. This is used to avoid certain exploits.
- ````reveal()```` function to change the baseTokenUri and improve the fairness of minting.
- ````withdraw()```` function. It allows to withdraw all ETH from the contract to the Owner address


Some basic Waffle tests are included, as well as a gas report from [hardhat-gas-reporter](https://www.npmjs.com/package/hardhat-gas-reporter). ERC721A is very efficient for batch minting, so I am including a gas report to see the difference in gas cost when minting 1, 5 and 10 NFTs

- General report
![gasreport](https://github.com/IpastorSan/ERC721A-nft-dutch-auction/blob/master/gas-report.png)
- Mint 1 NFT
![gasreport](https://github.com/IpastorSan/ERC721A-nft-dutch-auction/blob/master/gas-report.png)
- Mint 5 NFTs
![gasreport](https://github.com/IpastorSan/ERC721A-nft-dutch-auction/blob/master/gas-report.png)
- Mint 10 NFTs
![gasreport](https://github.com/IpastorSan/ERC721A-nft-dutch-auction/blob/master/gas-report.png)

## Useful commands to run the project 

You need to have Node.js (>=12.0)installed in your computer
You can find it [here](https://nodejs.org/en/)

## Install project dependencies
```bash
npm install
```

## Install dotenv to store environment variables and keep them secret

You need at least these variables in your .env file. BE SURE TO ADD IT TO GITIGNORE

*This is not compulsory, you could use public RPC URL, but Alchemys work really well and their free tier is more than enough (not sponsored)*
- DEVELOPMENT_ALCHEMY_KEY = "somestringhere"
- PRODUCTION_ALCHEMY_KEY = "somestringhere"

*Keys for deployment*
- PRIVATE_KEY_DEVELOPMENT = "somenumberhere"
- PRIVATE_KEY_PRODUCTION = "somenumberhere"


*To verify the contracts on Etherscan/polyscan etc*
- ETHERSCAN_KEY = "anothernumberhere"

# Use the project
## deploy contract 
run with this for testing: 
```bash
npx hardhat run scripts/deploy-script.js --network rinkeby 
```
run with this for mainnet: 
```bash
npx hardhat run scripts/deploy-script.js --network mainnet
```

# Run tests
```bash
npx hardhat test test/test.js 
```

## Verify contract 
```bash
npx hardhat verify --network **networkhere** **contractAddress**
```
