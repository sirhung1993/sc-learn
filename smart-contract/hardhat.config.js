require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
const fs = require('fs');
// const privateKey = "f5ab9ec554734dca63027c8b3e363dd5bc9330ed6600e9c5ad610dde9b6cbc23";
const privateKey = fs.readFileSync(".secret").toString().trim() || "f5ab9ec554734dca63027c8b3e363dd5bc9330ed6600e9c5ad610dde9b6cbc23";
const privateKeyMainet = fs.readFileSync(".secret-mainet").toString().trim()
const appId = "a1a7680eb1c4a6d3186f3ec9575fb357ad44ab13"

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 1337
    },
    mumbai: {
      chainId: 80001,
      url: `https://polygon-mumbai.infura.io/v3/6b9943f5168a413fa587274e83a90312`,
      accounts: [privateKey]
    },

    matic: {
      // Infura

      // url: `https://polygon-mainnet.infura.io/v3/${infuraId}`,
      chainId: 137,
      url: `https://rpc-mainnet.maticvigil.com/v1/${appId}`,
      accounts: [privateKeyMainet]
    }

  },

  etherscan: {
    apiKey: {
      polygon: "EA3WWAAN7NQRYY4IH6H9NQTEVPZRBNVIX5",
      polygonMumbai: "EA3WWAAN7NQRYY4IH6H9NQTEVPZRBNVIX5"
    }
  },

  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
};

