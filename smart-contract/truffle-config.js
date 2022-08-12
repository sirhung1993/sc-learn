require('babel-register');
require('babel-polyfill');
require('dotenv').config()
const privKeyrinkeby = "f5ab9ec554734dca63027c8b3e363dd5bc9330ed6600e9c5ad610dde9b6cbc23"
const PrivateKeyProvider = require("truffle-privatekey-provider");

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*" // Match any network id
    },
    kovan: {
      provider: () => new HDWalletProvider({ mnemonic : process.env.MNEMONIC, providerOrUrl : `https://kovan.infura.io/v3/${process.env.INFURA_APIKEY}`, addressIndex : 6 ,  numberOfAddresses : 10}),
      network_id: 42,
      gas: 8000000
    },
    rinkeby: {
      provider: () => new PrivateKeyProvider(privKeyrinkeby, "https://rinkeby.infura.io/v3/6b9943f5168a413fa587274e83a90312"),
      gasPrice: 50000000000, // 50 gwei,
      network_id: 4,
    },
  },
  contracts_directory: './contracts/',
  contracts_build_directory: './src/abis/',
  compilers: {
    solc: {
      version: " >=0.8.0",    // Fetch exact version from solc-bin (default: truffle's version)
      optimizer: {
        enabled: true,
        runs: 200
      }
      //evmVersion: "petersburg"
    }
  }
}
