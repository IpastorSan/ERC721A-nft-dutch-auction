const { ethers} = require("hardhat");
const { expect } = require("chai");


describe("ERC721, ERC721A, ERC1155, ERC1155D minting for gas comparison", () => {
  let erc721Factory;
  let erc721aFactory;
  let erc1155Factory;
  let erc1155FactoryD;
  let erc721;
  let erc721a;
  let erc1155;
  let erc1155d;
  let owner;
  let alice;
  let bob;
  let amount = 10;

  beforeEach(async () => {
    let signers = await ethers.getSigners()
    ownerAccount = signers[0]
    aliceAccount = signers[1]
    bobAccount = signers[2]
    carolAccount = signers[3]
    ineAccount = signers[4]

    owner = ownerAccount.address
    alice = aliceAccount.address 
    bob = bobAccount.address
    carol = carolAccount.address
    ine = ineAccount.address


    erc721aFactory = await ethers.getContractFactory("CoffeeMonster")

    const baseTokenUri = "https://ipfs.io/ipfs/whatever/"
    

    erc721a = await erc721aFactory.deploy(baseTokenUri)
    await erc721a.openSale();

  })

  describe(`Minting ${amount} unit of each token`, () => {


    it(`Should allow user to mint erc721a ${amount} token with exact price`, async () => {
      await erc721a.connect(aliceAccount).mintNFTs(amount, {value: ethers.utils.parseEther(`${1.05*amount}`)})
      expect(await erc721a.balanceOf(alice)).to.be.equal(amount)
    })

  })


  describe("Transfer of tokens", () => {


    it(`Should mint by Alice and try to transfer ${amount} erc721a token from user Alice to user Carol`, async () => {
      await erc721a.connect(aliceAccount).mintNFTs(amount, {value: ethers.utils.parseEther(`${1.05*amount}`)})
      for (let i = 0; i < amount ; i++){
        await erc721a.connect(aliceAccount).transferFrom(alice, carol, i)
      }
      expect(await erc721a.balanceOf(alice)).to.be.equal(0)
      expect(await erc721a.balanceOf(carol)).to.be.equal(amount)
    })

    
  })
  

})