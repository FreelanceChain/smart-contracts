const FctToken = artifacts.require("FctToken");

module.exports = function(deployer) {
  deployer.deploy(FctToken, "FCT Token", "FCT", 18, 500000);
};
