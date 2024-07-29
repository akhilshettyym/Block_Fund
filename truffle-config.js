const path = require("path");

module.exports = {
  // contracts_build_directory: path.join(__dirname, "frontend/src/contracts"),

  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,         // Port number of your Ganache instance
      network_id: "*",   // Match any network id
      gas: 800000000,      // Gas limit (set according to your Ganache configuration)
      gasPrice: 20000000000 // Gas price in wei (20 gwei)
    },
    // Add other network configurations here if needed
  },

  compilers: {
    solc: {
      version: "0.8.0",  // Match this with your contract's Solidity version
      // settings: {
      //   optimizer: {
      //     enabled: true,
      //     runs: 200
      //   }
      // }
    }
  }
};
