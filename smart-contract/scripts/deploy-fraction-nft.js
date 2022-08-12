const hre = require("hardhat");
const fs = require('fs');

async function main() {
    const SJFractionNFT = await hre.ethers.getContractFactory("SJFractions");
    const sJFractionNFT = await SJFractionNFT.deploy("Superjoi","SJF");
    await sJFractionNFT.deployed();
    console.log("SJFractions deployed to:", sJFractionNFT.address);


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
