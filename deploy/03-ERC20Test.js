const { network } = require("hardhat")
const {
  VERIFICATION_BLOCK_CONFIRMATIONS,
  developmentChains,
} = require("../helper-hardhat.config")
const { verify } = require("../utils/verify")

module.exports = async (getNamedAccounts, deployments) => {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const waitBlockConfirmations = developmentChains.includes(network.name)
    ? 1
    : VERIFICATION_BLOCK_CONFIRMATIONS

  log("----------------------------")
  const erc20Test = await deploy("ERC20Test", {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: waitBlockConfirmations,
  })

  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    log("Verifying...")
    await verify(erc20Test.address, [])
  }
}

module.exports.tags = ["all", "erc20test"]
