const hre = require("hardhat");
const fs = require('fs');

async function main() {
    const AirlineToken = await hre.ethers.getContractFactory("AirlineTokens");
    const airlineToken = await AirlineToken.deploy("0x1ee5B2BDaFb25769A3Fe0F0Fcc00E0C0035D598d","https://google.com");
    await airlineToken.deployed();
    console.log("AirlineTokens deployed to:", airlineToken.address);


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
