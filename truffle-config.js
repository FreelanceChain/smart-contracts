const dotenv = require('dotenv')
dotenv.config({ path: './.env.dev' })
const HDWalletProvider = require('@truffle/hdwallet-provider')

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },
    sepolia: {
      provider: () => new HDWalletProvider(process.env.ETH_MNEMONIC_PHRASE, `https://sepolia.infura.io/v3/${process.env.INFURA_PROJECT_ID}`),
      network_id: 11155111,
      gas: 5500000,
    },
    live: {
      provider: () => new HDWalletProvider(process.env.ETH_MNEMONIC_PHRASE, `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`),
      network_id: 1,
      production: true
    }
  },

  contracts_build_directory: "./build/",
  contracts_directory: './contracts',
  test_directory: "./test/",
  migrations_directory: "./migrations/",
  mocha: {
    // timeout: 100000
  },

  compilers: {
    solc: {
      version: "0.8.6",    // Fetch exact version from solc-bin (default: truffle's version)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    }
  },

  db: {
    enabled: false
  },

  plugins: ['truffle-plugin-verify'],

  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY,
  },
};