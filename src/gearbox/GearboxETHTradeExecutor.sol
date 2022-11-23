/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {MultiCall} from "gearbox_core/libraries/MultiCall.sol";
import {CreditAccountController} from "./CreditAccountController.sol";

contract GearboxETHTradeExecutor is BaseTradeExecutor, CreditAccountController {
    uint256 public feeCollected;
    uint256 public PERFORMANCE_FEE;

    constructor(
        address _vault,
        address _creditManager,
        address _addressProvider
    )
        BaseTradeExecutor(_vault)
        CreditAccountController(_addressProvider, _creditManager)
    {}

    /// @notice Emitted after new credit account is opened.
    /// @param account The address of creditAccount.
    /// @param fraxIn The amount of underlying tokens that were deposited.
    event OpenCreditAccount(address indexed account, uint256 fraxIn);

    function openCreditAccount(uint256 fraxIn, uint256 leverage)
        external
        onlyKeeper
    {
        uint256 ethValue = priceOracle().convert(
            (fraxIn * leverage) / MAX_BPS,
            address(FRAX),
            address(WETH)
        );

        MultiCall memory call = CreditAccountController._swapETHToStETHCall(
            ethValue,
            ethValue - 1
        );

        CreditAccountController._openCreditAccount(fraxIn, ethValue, call);
        emit OpenCreditAccount(address(creditAccount()), fraxIn);
    }

    /// @notice Emitted after colllateral is deposited into credit account.
    /// @param fraxIn The amount of underlying tokens that were deposited.
    event IncreaseCollateral(uint256 fraxIn);

    function increaseCollateral(uint256 fraxIn)
        external
        onlyKeeper
        creditAccountRequired
    {
        FRAX.approve(address(creditManager()), fraxIn);
        MultiCall[] memory calls = new MultiCall[](1);
        calls[0] = CreditAccountController._addCollateralCall(fraxIn);
        creditFacade().multicall(calls);
        emit IncreaseCollateral(fraxIn);
    }

    /// @notice Emitted when leverage is updated.
    /// @param oldLeverage The value of old leverage.
    /// @param newLeverage The value of new leverage.
    event UpdatedLeverage(uint256 oldLeverage, uint256 newLeverage);

    function setLeverage(uint256 newLeverage) external onlyKeeper {
        uint256 currentLeverage = CreditAccountController.getLeverage();
        uint256 totalEquity = CreditAccountController.positionInWantToken();
        bool toBorrow = newLeverage > currentLeverage;

        if (toBorrow) {
            uint256 borrowedInWant = (totalEquity *
                (newLeverage - currentLeverage)) / MAX_BPS;
            uint256 ethIn = priceOracle().convert(
                borrowedInWant,
                address(FRAX),
                address(WETH)
            );
            increaseLeverage(ethIn);
        } else {
            uint256 borrowOutWant = (totalEquity *
                (currentLeverage - newLeverage)) / MAX_BPS;
            uint256 ethOut = priceOracle().convert(
                borrowOutWant,
                address(FRAX),
                address(WETH)
            );

            decreaseLeverage(ethOut);
        }

        emit UpdatedLeverage(currentLeverage, newLeverage);
    }

    /// @notice Emitted when more funds are borrowed.
    /// @param borrowedFunds The value of funds borrowed in eth .
    event DebtIncrease(uint256 borrowedFunds);

    function increaseLeverage(uint256 ethIn)
        public
        onlyKeeper
        creditAccountRequired
    {
        MultiCall[] memory calls = new MultiCall[](2);
        calls[0] = CreditAccountController._increaseDebtCall(ethIn);
        uint256 amountOut = priceOracle().convert(
            ethIn,
            address(WETH),
            address(STETH)
        );
        amountOut = accountOutputSlippage(amountOut, CURVE_ETH_STETH_SLIPPAGE);
        calls[1] = CreditAccountController._swapETHToStETHCall(
            ethIn,
            amountOut - 1
        );
        creditFacade().multicall(calls);
        emit DebtIncrease(ethIn);
    }

    /// @notice Emitted when more funds are payed back.
    /// @param requestedFunds The value of funds requested for decrease.
    /// @param payedFunds The value of funds payed back in eth .
    event DebtDecrease(uint256 requestedFunds, uint256 payedFunds);

    function decreaseLeverage(uint256 ethOut)
        public
        onlyKeeper
        creditAccountRequired
    {
        uint256 wethBal = WETH.balanceOf(address(creditAccount()));
        MultiCall[] memory calls = new MultiCall[](1);
        uint256 amountIn = priceOracle().convert(
            ethOut,
            address(WETH),
            address(STETH)
        );
        amountIn = accountInputSlippage(amountIn, CURVE_ETH_STETH_SLIPPAGE);
        calls[0] = CreditAccountController._swapStETHToETHCall(
            amountIn,
            ethOut
        );
        creditFacade().multicall(calls);

        uint256 swapResult = WETH.balanceOf(address(creditAccount())) - wethBal;

        calls[0] = CreditAccountController._decreaseDebtCall(swapResult);

        creditFacade().multicall(calls);

        emit DebtDecrease(ethOut, swapResult);
    }

    function multicall(MultiCall[] memory calls) external onlyKeeper {
        creditFacade().multicall(calls);
    }

    /// @notice Emitted after new credit account is opened.
    /// @param account The address of creditAccount.
    /// @param fraxOut Frax recevied on creditAccount closure
    event CloseCreditAccount(address indexed account, uint256 fraxOut);

    function closeCreditAccount() external onlyKeeper creditAccountRequired {
        uint256 oldBal = FRAX.balanceOf(address(this));
        CreditAccountController._closeCreditAccount();
        uint256 newBal = FRAX.balanceOf(address(this));
        emit CloseCreditAccount(address(creditAccount()), newBal - oldBal);
    }

    function closeCreditAccountManual(
        uint256 skipTokenMask,
        MultiCall[] memory additionalCalls
    ) external onlyKeeper creditAccountRequired {
        creditFacade().closeCreditAccount(
            address(this),
            skipTokenMask,
            false,
            additionalCalls
        );
    }

    /// @notice Emitted when yield is claimed.
    /// @param yield The amount of yield that is claimed.
    event Claim(uint256 yield);

    function claimYield() external onlyKeeper {
        // yieldAccumulated = stETH value - eth debt
        uint256 totalstETHInWantToken = priceOracle().convert(
            getStETHPriceInETH(STETH.balanceOf(address(creditAccount()))),
            address(WETH),
            address(FRAX)
        );

        (, , uint256 borrowedAmountAndFeesAndInterest) = creditManager()
            .calcCreditAccountAccruedInterest(address(creditAccount()));

        uint256 totalBorrowedETHInWantToken = priceOracle().convert(
            borrowedAmountAndFeesAndInterest,
            address(WETH),
            address(FRAX)
        );

        uint256 yieldAccumulated = totalstETHInWantToken >
            totalBorrowedETHInWantToken
            ? (totalstETHInWantToken - totalBorrowedETHInWantToken)
            : 0;
        if (yieldAccumulated > 0) {
            uint256 yieldAccumulatedInStETH = priceOracle().convert(
                yieldAccumulated,
                address(FRAX),
                address(STETH)
            );

            // convert stETH to wantToken via swap.
            uint256 claimedYield = CreditAccountController._convertStETHToFrax(
                yieldAccumulatedInStETH
            );

            feeCollected += (claimedYield * PERFORMANCE_FEE) / MAX_BPS;
            emit Claim(claimedYield);
        }
    }

    function collectFee() external onlyKeeper {
        uint256 amount = feeCollected;
        feeCollected = 0;
        IERC20(vaultWantToken()).transfer(governance(), amount);
    }

    function totalFunds()
        external
        view
        returns (uint256 posValue, uint256 lastUpdatedBlock)
    {
        posValue =
            FRAX.balanceOf(address(this)) +
            CreditAccountController.positionInWantToken() -
            feeCollected;
        return (posValue, block.number);
    }

    /// @notice event emitted when slippage is updated
    event UpdatedSlippage(
        uint256 indexed oldSlippage,
        uint256 indexed newSlippage,
        uint256 indexed index
    );

    /// @notice Keeper function to set max slippage acceptable for accounting funds.
    /// @param _slippage Max accepted slippage during pricing of funds
    function setSlippageBound(uint256 _slippage) external onlyGovernance {
        uint256 oldSlippage = CreditAccountController.CURVE_SLIPPAGE_BOUND;

        CreditAccountController._setSlippageBound(_slippage);
        emit UpdatedSlippage(oldSlippage, _slippage, 0);
    }

    /// @notice Keeper function to set max accepted slippage of curve swaps
    /// @param _slippage Max accepted slippage during taking leveraged position
    function setCurveSwapSlippage(uint256 _slippage) external onlyGovernance {
        uint256 oldSlippage = CreditAccountController.CURVE_ETH_STETH_SLIPPAGE;

        CreditAccountController._setCurveSwapSlippage(_slippage);
        emit UpdatedSlippage(oldSlippage, _slippage, 1);
    }

    /// @notice Keeper function to set max accepted slippage of eth frax swap.
    /// @param _slippage Max accepted slippage during closing account
    function setUniFRAXSlippage(uint256 _slippage) external onlyGovernance {
        uint256 oldSlippage = CreditAccountController
            .UNISWAP_ETH_FRAX_POOL_SLIPPAGE;

        CreditAccountController._setUniFRAXSlippage(_slippage);
        emit UpdatedSlippage(oldSlippage, _slippage, 2);
    }

    function setPerformanceFee(uint256 _performanceFee)
        external
        onlyGovernance
    {
        PERFORMANCE_FEE = _performanceFee;
    }
}
