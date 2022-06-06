const { ethers, waffle } = require("hardhat");
const { expect } = require("chai");
const { deployMockContract } = require("ethereum-waffle");

describe("NFT contract creation, NFT minting, royalties, withdraw,", () => {
  let nftFactory;
  let nft;
  let owner;
  let alice;
  let bob;

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

    nftFactory = await ethers.getContractFactory("CoffeeMonster")

    const baseTokenUri = "https://ipfs.io/ipfs/whatever/"
    
    nft = await nftFactory.deploy(baseTokenUri)



  })

  describe("Minting in Public Sale with public sale open", () => {

     beforeEach(async () => {
       await nft.openPublicSale();
     })

     it("Should try to open sale again, fail Public Sale is already Open", async () => {
       await expect(nft.openPublicSale()).to.be.revertedWith("Sale is already Open!")
     })

    it("Should open sale and allow user (not owner) to mint 1 token with exact price", async () => {
      await nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("0.1")})
      expect(await nft.balanceOf(alice)).to.be.equal(1)
    })

    it("Should open sale and allow user (not owner) to mint 2 tokens with exact price", async () => {
      await nft.connect(aliceAccount).mintNFTs(2, {value: ethers.utils.parseEther("0.2")})
      expect(await nft.balanceOf(alice)).to.be.equal(2)
    })

    it("Should open sale but fail to allow user (not owner) to mint more than the max amount of tokens per address", async () => {
      await expect(nft.connect(aliceAccount).mintNFTs(6, {value: ethers.utils.parseEther("0.6")})).to.be.revertedWith('Cannot mint more than 5 NFTs per wallet')
    })

    it("Should open sale but fail to allow user (not owner) to mint if not enought ether sent", async () => {
      await expect( nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("0.00001")})).to.be.revertedWith('Not enough/too much ether sent')
    })

    it("Should open sale but fail to allow user (not owner) to mint if more ether sent than necessary", async () => {
      await expect( nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("4")})).to.be.revertedWith('Not enough/too much ether sent')
    })

  })

  describe("Transfer of tokens", () => {

    beforeEach(async () => {
      await nft.openPublicSale();
    })

    it("Should mint by Alice and try to transfer 1 token from user Alice to user Carol", async () => {
      await nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("0.1")})
      await nft.connect(aliceAccount).transferFrom(alice, carol, await nft.getCurrentId()-1)

      expect(await nft.balanceOf(alice)).to.be.equal(0)
      expect(await nft.balanceOf(carol)).to.be.equal(1)
    })
  })
  
  describe("Withdrawal of funds", () => {

    it("should sell 2 NFTs and fail to allow withdrawal of funds by not owner address", async() => {
      
        await nft.openPublicSale()
        await nft.connect(aliceAccount).mintNFTs(2, {value: ethers.utils.parseEther("0.2")})
        expect(await nft.balanceOf(alice)).to.be.equal(2)
  
        await expect(nft.connect(aliceAccount).withdraw()).to.revertedWith("Ownable: caller is not the owner")
      })

    it("Should sell 2 NFTs and allow owner to withdraw funds", async () => {
      await nft.openPublicSale()
        await nft.connect(aliceAccount).mintNFTs(2, {value: ethers.utils.parseEther("0.2")})
        expect(await nft.balanceOf(alice)).to.be.equal(2)
  
        await expect(() => nft.withdraw()).to.changeEtherBalance(ownerAccount, ethers.utils.parseEther("0.2"))
    })
  })

})