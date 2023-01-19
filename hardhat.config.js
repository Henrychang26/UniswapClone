require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()

// const ISwapRouterAddress =
//   process.env.ISwapRouterAddress || 0xe592427a0aece92de3edee1f18e0157c05861564
// const USDCAddress =
//   process.env.USDCAddress || 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
// const DAIAddress =
//   process.env.DAIAddress || 0x6b175474e89094c44da98b954eedeac495271d0f
// const WETHAddress =
//   process.env.WETHAddress || 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
const GOERLI_RPC_URL =
  process.env.GOERLI_RPC_URL ||
  "https://eth-goerli.g.alchemy.com/v2/cSjTaH_-9k_Gf9VNjKL95zldaiCNfVL9"
const MAINNET_RPC_URL =
  process.env.MAINNET_RPC_URL ||
  "https://eth-mainnet.g.alchemy.com/v2/5AGf94eZJ1ybpz-34w6oxatTfu4OkAKs"
const POLYGON_RPC_URL =
  process.env.POLYGON_RPC_URL ||
  "https://polygon-mainnet.g.alchemy.com/v2/d_YfR3Wb1MndlPeeFWVwjIfliPZrTnQm"
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY
const REPORT_GAS = process.env.REPORT_GAS || false
const PRIVATE_KEY = process.env.PRIVATE_KEY
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      // // If you want to do some forking, uncomment this
      // forking: {
      //   url: MAINNET_RPC_URL
      // }
      chainId: 31337,
    },
    localhost: {
      chainId: 31337,
    },
    goerli: {
      url: GOERLI_RPC_URL,
      accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
      //   accounts: {
      //     mnemonic: MNEMONIC,
      //   },
      saveDeployments: true,
      chainId: 5,
    },
    mainnet: {
      url: MAINNET_RPC_URL,
      accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
      //   accounts: {
      //     mnemonic: MNEMONIC,
      //   },
      saveDeployments: true,
      chainId: 1,
    },
    polygon: {
      url: POLYGON_RPC_URL,
      accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
      saveDeployments: true,
      chainId: 137,
    },
  },
  etherscan: {
    // yarn hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
    apiKey: {
      goerli: ETHERSCAN_API_KEY,
      polygon: POLYGONSCAN_API_KEY,
    },
    customChains: [
      {
        network: "goerli",
        chainId: 5,
        urls: {
          apiURL: "https://api-goerli.etherscan.io/api",
          browserURL: "https://goerli.etherscan.io",
        },
      },
    ],
  },
  gasReporter: {
    enabled: REPORT_GAS,
    currency: "USD",
    outputFile: "gas-report.txt",
    noColors: true,
    // coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
  contractSizer: {
    runOnCompile: false,
    only: ["Raffle"],
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
      1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
    },
    player: {
      default: 1,
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.7",
      },
      {
        version: "0.4.24",
      },
    ],
  },
  mocha: {
    timeout: 500000, // 500 seconds max for running tests
  },
}
