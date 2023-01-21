const { network, ethers } = require("hardhat")
const {
  developmentChains,
  VERIFICATION_BLOCK_CONFIRMATIONS,
  networkConfig,
} = require("../helper-hardhat.config")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId
  const waitBlockConfirmations = developmentChains.includes(network.name)
    ? 1
    : VERIFICATION_BLOCK_CONFIRMATIONS

  const INonfungiblePositionManager = await ethers.getContract(
    "INonfungiblePositionManager"
  )
  const iNonfungiblePositionManager = await INonfungiblePositionManager.deploy()
  const factory = networkConfig[chainId]["factory"]
  const WETH9 = networkConfig[chainId]["WETH9"]
  const args = [iNonfungiblePositionManager, factory, WETH9]

  log("Deploying Liquidity Pool")
  const liquidity = await deploy("Liquidity", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: waitBlockConfirmations,
  })

  if (!developmentChains.includes(network.name) && ETHERSCAN_API_KEY) {
    log("Verifying...")
    await verify(liquidity.address, [])
  }
}

module.exports.tags = ["all", "liquidity"]
