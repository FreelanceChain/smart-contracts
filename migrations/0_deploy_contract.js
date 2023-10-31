const FreelanceChainPlatform = artifacts.require('FreelanceChainPlatform');
// const IERC20 = artifacts.require('IERC20');

module.exports = async function(deployer, network, accounts) {
    const fctTokenAddress = '0xD69154f833c740E6D9fa9307B66b58d4afBeee4f';
    const daiTokenAddress = '0x6b175474e89094c44da98b954eedeac495271d0f';
    const usdtTokenAddress = '0xdAC17F958D2ee523a2206206994597C13D831ec7';
    const usdcTokenAddress = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';

    // const fctToken = await IERC20.at(fctTokenAddress);
    // const daiToken = await IERC20.at(daiTokenAddress);
    // const usdtToken = await IERC20.at(usdtTokenAddress);
    // const usdcToken = await IERC20.at(usdcTokenAddress);

    await deployer.deploy(FreelanceChainPlatform, fctTokenAddress, daiTokenAddress, usdtTokenAddress, usdcTokenAddress);
};
