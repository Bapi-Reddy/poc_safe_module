// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Registry.sol";
import "forge-std/console.sol";

contract AaveController is Registry {
    uint256 public aaveSlippage = 10;

    function addCollateral(uint256 usdcAmount) public {
        usdc.approve(address(aavePool), usdcAmount);
        aavePool.supply(address(usdc), usdcAmount, address(this), 0);
    }
}
