const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("NFTMarket", function() {
  before(function() {
    this.timeout(10000) // 10 second timeout for setup
  })
    it("Should mint and trade NFt", async function() {

      /* test receive contracts addresses */
      const Marketn = await ethers.getContractFactory('NFTMarket')
      const marketn = await Marketn.deploy()
      await marketn.deployed()
      const marketAddress = marketn.address


  /* test to receive listing price and aution price */
      const NFt = await ethers.getContractFactory('NFT')
      const nft = await NFt.deploy('marketAddress')
      await nft.deployed() 
      const nftContractAddress =nft.address

      let listingPrice = await marketn.getListingPrice()
      listingPrice = listingPrice.toString()
  
      const auctionPrice = ethers.utils.parseUnits('100', 'ether')

        /* test for minting */
        await nft.createToken('https-t1')
        await nft.createToken('https-t2')
        await marketn.createMarketItem(nftContractAddress , 1 ,auctionPrice ,0,{value: listingPrice})
        await marketn.createMarketItem(nftContractAddress , 2 ,auctionPrice ,1 ,{value: listingPrice})

        /* test for different addresses  from diffrent users  - test accounts */
          /* return an array of however many addresses  */

          const [_, buyerAddress] = await ethers.getSigners()

          /* create a market sale with address , id and price  */
          await marketn.connect(buyerAddress).createMarketSale(nftContractAddress , 1,{value: auctionPrice})

          const items = await marketn.fetchMarketItems()

          /* test  out all the items */
           console.log ('items' , items )


});
}); 
