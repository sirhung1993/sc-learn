const hre = require("hardhat");
const fs = require('fs');

async function main() {
    const CampaignContract = await hre.ethers.getContractFactory("CampaignContract");
    const campaignContract = await CampaignContract.deploy();
    await campaignContract.deployed();
    console.log("CampaignContract deployed to:", campaignContract.address);


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
