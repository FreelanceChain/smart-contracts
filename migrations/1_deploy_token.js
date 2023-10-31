const FreelanceChainToken = artifacts.require("FreelanceChainToken");

module.exports = function(deployer) {
  deployer.deploy(FreelanceChainToken, "FreelanceChain Token", "FCT", 18, 500000);
};
