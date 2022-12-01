// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Registry.sol";
import "forge-std/console.sol";

contract AaveController is Registry {
    // uint256 public aaveSlippage = 10;

    function addCollateral(uint256 usdcAmount) public {
        usdc.approve(address(aavePool), usdcAmount);
        aavePool.supply(address(usdc), usdcAmount, address(this), 0);
    }

    function borrowBTC(uint256 wbtcAmt) public {
        aavePool.borrow(address(wbtc), wbtcAmt, 2, 0, address(this));
    }

    function borrowETH(uint256 wethAmt) public {
        aavePool.borrow(address(weth), wethAmt, 2, 0, address(this));
    }

    function repayBTC(uint256 wbtcAmt) public {
        wbtc.approve(address(aavePool), wbtcAmt);
        aavePool.repay(address(wbtc), wbtcAmt, 2, address(this));
    }

    function repayETH(uint256 wethAmt) public {
        weth.approve(address(aavePool), wethAmt);
        aavePool.repay(address(weth), wethAmt, 2, address(this));
    }

    function removeCollateral(uint256 usdcAmt) public {
        aavePool.withdraw(address(usdc), usdcAmt, address(this));
    }

    //TODO: need view function for aave hf

    //TODO: need view function for token ltv factor.
}
