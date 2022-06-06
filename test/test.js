const { ethers, waffle } = require("hardhat");
const { expect } = require("chai");
const { deployMockContract } = require("ethereum-waffle");

const increaseTimeInSeconds = async(seconds, mine=false) => {
  await ethers.provider.send("evm_increaseTime", [seconds]);
  if(mine){
    await ethers.provider.send("evm_mine", [])
  }
}

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

  describe("Minting in Public Sale with public sale open in Phase 1", () => {

     beforeEach(async () => {
       await nft.openSale();
     })

     it("Should try to open sale again, fail Public Sale is already Open", async () => {
       await expect(nft.openSale()).to.be.revertedWith("Sale is already Open!")
     })

    it("Should open sale and allow user (not owner) to mint 1 token with exact price", async () => {
      await nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("1.05")})
      expect(await nft.balanceOf(alice)).to.be.equal(1)
    })

    it("Should open sale and allow user (not owner) to mint 2 tokens with exact price", async () => {
      await nft.connect(aliceAccount).mintNFTs(2, {value: ethers.utils.parseEther("2.1")})
      expect(await nft.balanceOf(alice)).to.be.equal(2)
    })

    it("Should open sale but fail to allow user (not owner) to mint more than the max amount of tokens per address", async () => {
      await expect(nft.connect(aliceAccount).mintNFTs(6, {value: ethers.utils.parseEther("6.3")})).to.be.revertedWith('Max mint per txn reached for phase 1')
    })

    it("Should open sale but fail to allow user (not owner) to mint if not enought ether sent", async () => {
      await expect( nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("0.00001")})).to.be.revertedWith('Not enough/too much Ether sent')
    })

    it("Should open sale but fail to allow user (not owner) to mint if more ether sent than necessary", async () => {
      await expect( nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("4")})).to.be.revertedWith('Not enough/too much Ether sent')
    })

  })

  describe("Minting in Public Sale with public sale open in all price steps of Phase 1", () => {

    beforeEach(async () => {
      await nft.openSale();
    })

    it("Should buy NFT with price 1ETH after waiting 30 mins. 1st price step", async () => {
      increaseTimeInSeconds(1801, true)
      await nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("1")})
      expect(await nft.balanceOf(alice)).to.be.equal(1)
    })

    it("Should Fail buy NFT with price 1.05ETH after waiting 30 mins(overprice). 1st price step", async () => {
      increaseTimeInSeconds(1801, true)
      await expect(nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("1.05")})).to.be.revertedWith("Not enough/too much Ether sent")
      expect(await nft.balanceOf(alice)).to.be.equal(0)
    })

    it("Should Fail buy NFT with price 0.95ETH after waiting 30 mins(underprice). 1st price step", async () => {
      increaseTimeInSeconds(1801, true)
      await expect(nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("0.95")})).to.be.revertedWith("Not enough/too much Ether sent")
      expect(await nft.balanceOf(alice)).to.be.equal(0)
    })

    it("Should buy NFT with price 0.95ETH after waiting 60 mins. 1st price step", async () => {
      increaseTimeInSeconds((30*60*2)+1, true)
      await nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("0.95")})
      expect(await nft.balanceOf(alice)).to.be.equal(1)
    })

    it("Should Fail buy NFT with price 1ETH after waiting 60 mins(overprice). 1st price step", async () => {
      increaseTimeInSeconds((30*60*2)+1, true)
      await expect(nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("1")})).to.be.revertedWith("Not enough/too much Ether sent")
      expect(await nft.balanceOf(alice)).to.be.equal(0)
    })

    it("Should Fail buy NFT with price 0.90ETH after waiting 60 mins(underprice). 1st price step", async () => {
      increaseTimeInSeconds((30*60*2)+1, true)
      await expect(nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("0.90")})).to.be.revertedWith("Not enough/too much Ether sent")
      expect(await nft.balanceOf(alice)).to.be.equal(0)
    })
 })

 describe("Minting in Public Sale with public sale open in all price steps of Phase 2", () => {

  beforeEach(async () => {
    await nft.openSale();
  })

  it("Should buy NFT with price 0.255ETH after waiting 8 hours. Last price 0.3", async () => {
    increaseTimeInSeconds((30*60*15)+1, true)
    await nft.connect(aliceAccount).mintNFTs(1,{value: ethers.utils.parseEther("0.30")})
    increaseTimeInSeconds((30*60*1), true)
    await nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("0.255")})
    expect(await nft.balanceOf(alice)).to.be.equal(2)
  })

  it("Should buy NFT with price 0.425ETH after waiting 8 hours. Last price 0.5", async () => {
    await increaseTimeInSeconds((30*60*11)+1, true)
    await nft.connect(aliceAccount).mintNFTs(1,{value: ethers.utils.parseEther("0.50")})
    increaseTimeInSeconds((30*60*6), true)
    await nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("0.425")})
    expect(await nft.balanceOf(alice)).to.be.equal(2)
  })

 })

 describe("Minting in Public Sale with public sale open in Phase 3", () => {

  beforeEach(async () => {
    await nft.openSale();
  })

  it("Should buy NFT with price 0.15ETH after waiting 24 hours. Last price 0.3", async () => {
    increaseTimeInSeconds((30*60*15)+1, true)
    await nft.connect(aliceAccount).mintNFTs(1,{value: ethers.utils.parseEther("0.30")})
    increaseTimeInSeconds((30*60*49), true)
    await nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("0.15")})
    expect(await nft.balanceOf(alice)).to.be.equal(2)
  })

  it("Should buy NFT with price 0.425ETH after waiting 8 hours. Last price 0.5", async () => {
    await increaseTimeInSeconds((30*60*11)+1, true)
    await nft.connect(aliceAccount).mintNFTs(1,{value: ethers.utils.parseEther("0.50")})
    increaseTimeInSeconds((30*60*53)+1, true)
    await nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("0.25")})
    expect(await nft.balanceOf(alice)).to.be.equal(2)
  })
 })


  describe("Transfer of tokens", () => {

    beforeEach(async () => {
      await nft.openSale();
    })

    it("Should mint by Alice and try to transfer 1 token from user Alice to user Carol", async () => {
      await nft.connect(aliceAccount).mintNFTs(1, {value: ethers.utils.parseEther("1.05")})
      await nft.connect(aliceAccount).transferFrom(alice, carol, await nft.tokenId())

      expect(await nft.balanceOf(alice)).to.be.equal(0)
      expect(await nft.balanceOf(carol)).to.be.equal(1)
    })
  })
  
  describe("Withdrawal of funds", () => {

    it("should sell 2 NFTs and fail to allow withdrawal of funds by not owner address", async() => {
      
        await nft.openSale()
        await nft.connect(aliceAccount).mintNFTs(2, {value: ethers.utils.parseEther("2.1")})
        expect(await nft.balanceOf(alice)).to.be.equal(2)
  
        await expect(nft.connect(aliceAccount).withdraw()).to.revertedWith("Ownable: caller is not the owner")
      })

    it("Should sell 2 NFTs and allow owner to withdraw funds", async () => {
      await nft.openSale()
        await nft.connect(aliceAccount).mintNFTs(2, {value: ethers.utils.parseEther("2.1")})
        expect(await nft.balanceOf(alice)).to.be.equal(2)
  
        await expect(() => nft.withdraw()).to.changeEtherBalance(ownerAccount, ethers.utils.parseEther("2.1"))
    })
  })

})