// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Registry.sol";
import "forge-std/console.sol";

contract GLPController is Registry {
    uint256 public gmxSlippage = 10;

    uint256 stakedGLP;

    function depositUSDC(uint256 usdcAmount) public returns (uint256 glpOut) {
        usdc.approve(address(glpManager), usdcAmount);

        uint256 estimateUSDGOut = adjustOutputSlippage(usdcAmount, gmxSlippage);
        uint256 estimatedGlpOut = estimateGlpPrice(usdcAmount, true);
        console.log("glp estimated", estimatedGlpOut);
        glpOut = rewardsRouter.mintAndStakeGlp(
            address(usdc),
            usdcAmount,
            estimateUSDGOut,
            0
        );
        stakedGLP += glpOut;
    }

    function burnStakedGLP(uint256 glpAmount) public returns (uint256 usdcOut) {
        uint256 estimatedUSDCOut = estimateUSDCOut(glpAmount, false);
        estimatedUSDCOut = adjustOutputSlippage(estimatedUSDCOut, gmxSlippage);

        console.log("estimate usdc out", estimatedUSDCOut);

        usdcOut = rewardsRouter.unstakeAndRedeemGlp(
            address(usdc),
            glpAmount,
            estimatedUSDCOut,
            address(this)
        );
        return usdcOut;
    }

    function burnStakedGLPWBTC(uint256 glpAmount)
        public
        returns (uint256 wethOut)
    {
        wethOut = rewardsRouter.unstakeAndRedeemGlp(
            0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f,
            glpAmount,
            0,
            address(this)
        );
        return wethOut;
    }

    function withdrawUSDC(uint256 usdc) public {
        uint256 estimatedGlpToBurn = estimateGlpPrice(usdc, false);
        burnStakedGLP(estimatedGlpToBurn);
    }

    function adjustOutputSlippage(uint256 amt, uint256 slippage)
        internal
        pure
        returns (uint256)
    {
        return (amt * (MAX_BPS - slippage)) / MAX_BPS;
    }

    function estimateGlpPrice(uint256 usdcAmt, bool buyGlp)
        internal
        view
        returns (uint256)
    {
        // uint256 aum = glpManager.getAum(buyGlp) / glpManager.PRICE_PRECISION();
        // uint256 totalSupply = glp.totalSupply() / (10**glp.decimals());

        // uint256 estGlpPrice = aum / totalSupply;

        // uint256 estGlpOut = ((usdcAmt / 1e6) / estGlpPrice) *
        //     (10**glp.decimals());

        uint256 estGlpOut = (usdcAmt *
            glp.totalSupply() *
            glpManager.PRICE_PRECISION()) / (1e6 * glpManager.getAum(buyGlp));

        return estGlpOut;
    }

    function estimateUSDCOut(uint256 glpAmt, bool buyGlp)
        internal
        view
        returns (uint256)
    {
        // uint256 aum = glpManager.getAum(buyGlp) / glpManager.PRICE_PRECISION();
        // uint256 totalSupply = glp.totalSupply() / (10**glp.decimals());

        // uint256 estGlpPrice = aum / totalSupply;

        // uint256 estUsdcOut = ((glpAmt / (10**glp.decimals())) * estGlpPrice) *
        //     1e6;

        uint256 estUsdcOut = (glpAmt * 1e6 * glpManager.getAum(buyGlp)) /
            (glpManager.PRICE_PRECISION() * glp.totalSupply());
        return estUsdcOut;
    }
}
