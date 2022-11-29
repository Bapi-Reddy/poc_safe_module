// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/gmx/IRewardsRouterV2.sol";
import "./interfaces/gmx/IGLPManager.sol";
import "./interfaces/gmx/IVault.sol";

import "./interfaces/aave/IAavePoolV3.sol";
import "./interfaces/IERC20.sol";

contract Registry {
    uint256 public constant MAX_BPS = 1e4;

    IRewardsRouterV2 public rewardsRouter =
        IRewardsRouterV2(payable(0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1));

    IGLPManager public glpManager =
        IGLPManager(0x321F653eED006AD1C29D174e17d96351BDe22649);

    IVault public vault = IVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);

    IAavePoolV3 public aavePool =
        IAavePoolV3(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

    IERC20 public usdc = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

    IERC20 public glp = IERC20(0x4277f8F2c384827B5273592FF7CeBd9f2C1ac258);

    IERC20 public usdg = IERC20(0x45096e7aA921f27590f8F19e457794EB09678141);

    IERC20 public wbtc = IERC20(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    IERC20 public weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

}
