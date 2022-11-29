// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/AaveController.sol";

// import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract AaveControllerTest is Test {
    AaveController public cont;
    IERC20 public usdc;

    function setUp() public {
        cont = new AaveController();
        usdc = cont.usdc();
    }

    function testSetup() external {
        uint256 usdcAmount = 1e6 * 1e3;
        deal(address(usdc), address(this), usdcAmount);
        usdc.transfer(address(cont), usdcAmount);
        cont.addCollateral(usdcAmount);

        // console.log("glpMinted", glpMinted);

        // vm.roll(block.number + 100000000);
        // vm.warp(block.timestamp + 100000000);

        // uint256 usdcOut = cont.burnStakedGLPWBTC(glpMinted);

        // console.log("usdcOut", usdcOut);
        // console.log("usdc bal", usdc.balanceOf(address(cont)));
    }
}
