// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Registry.sol";
import "forge-std/console.sol";

contract GLPController is Registry {
    uint256 public gmxSlippage = 10;

    uint256 stakedGLP;

    function depositUSDC(uint256 usdcAmount)
        public
        returns (
            address to,
            uint256 value,
            bytes memory callData
        )
    {
        uint256 estimateUSDGOut = adjustOutputSlippage(usdcAmount, gmxSlippage);
        uint256 estimatedGlpOut = estimateGlpPrice(usdcAmount, true);
        // console.log("glp estimated", estimatedGlpOut);
        // glpOut = rewardsRouter.mintAndStakeGlp(
        //     address(usdc),
        //     usdcAmount,
        //     estimateUSDGOut,
        //     0
        // );
        // stakedGLP += glpOut;

        callData = abi.encodeCall(
            rewardsRouter.mintAndStakeGlp,
            (address(usdc), usdcAmount, estimateUSDGOut, 0)
        );
        to = address(rewardsRouter);
        value = 0;
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
            address(wbtc),
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

    function getGLPDelta(uint256 glpAmount)
        public
        returns (uint256 wethDelta, uint256 wbtcDelta)
    {
        wethDelta =
            (vault.poolAmounts(address(weth)) * glpAmount) /
            glp.totalSupply();
        wbtcDelta =
            (vault.poolAmounts(address(wbtc)) * glpAmount) /
            glp.totalSupply();
    }

    function getHedgeRatio() public returns (uint256 ratio) {
        uint256 glpAmount = 1000e18; // 1000 glp tokens
        (uint256 wethDelta, uint256 wbtcDelta) = getGLPDelta(glpAmount);
        uint256 wethDeltaInUsd = (wethDelta *
            vault.getMinPrice(address(weth))) / WETH_PRECISION;
        uint256 wbtcDeltaInUsd = (wbtcDelta *
            vault.getMinPrice(address(wbtc))) / WBTC_PRECISION;
        uint256 netDelta = wethDeltaInUsd + wbtcDeltaInUsd;
        uint256 glpPrice = getGLPPrice();
        ratio = (netDelta * MAX_BPS) / ((glpAmount * glpPrice) / GLP_PRECISION);
    }

    function getGLPRatio(uint256 usdc_ltv, uint256 desired_hf)
        public
        returns (uint256 ratio)
    {
        uint256 numerator = usdc_ltv;
        uint256 denominator = ((desired_hf * getHedgeRatio()) / MAX_BPS) +
            usdc_ltv -
            ((usdc_ltv * getHedgeRatio()) / MAX_BPS);
        ratio = (numerator * MAX_BPS) / denominator;
    }

    function getGLPPrice() public returns (uint256 glpPrice) {
        glpPrice =
            ((glpManager.getAum(true) * vault.PRICE_PRECISION()) /
                glp.totalSupply()) /
            glpManager.PRICE_PRECISION();
    }

    function openPositionParams(uint256 usdcAmount, uint256 desired_hf)
        public
        returns (
            uint256 glpPurchase,
            uint256 aaveUSDCDeposit,
            uint256 wbtcShort,
            uint256 wethShort
        )
    {
        uint256 usdc_ltv = 7500; //TODO: replace it with value fetched from aave.
        uint256 glpRatio = getGLPRatio(usdc_ltv, desired_hf);
        uint256 glpUSD = (usdcAmount * glpRatio) / MAX_BPS;
        aaveUSDCDeposit = usdcAmount - glpUSD;
        glpPurchase = ((((glpUSD * vault.PRICE_PRECISION()) / getGLPPrice()) *
            GLP_PRECISION) / USDC_PRECISION);
        (wethShort, wbtcShort) = getGLPDelta(glpPurchase);
    }
}
