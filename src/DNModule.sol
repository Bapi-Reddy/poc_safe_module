// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ICurveGauge.sol";

import "./GLPController.sol";

import "./AaveController.sol";
import {TaskDemo} from "./TaskDemo.sol";

import "./Enum.sol";

interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (bool success);
}

contract DNModule is GLPController, AaveController, TaskDemo {
    mapping(address => bool) public registeredSafes;

    constructor(address _ops) TaskDemo(_ops) {}

    function registerSafe() public {
        require(!registeredSafes[msg.sender], "already safe");
        registeredSafes[msg.sender] = true;
    }

    function initPosition(uint256 usdcAmt) public onlySafe {
        //Gelato task
        registerSafe(msg.sender);
        addFunds(1e6);

        usdcAmt -= 1e6;

        // GLP Position

        GnosisSafe(msg.sender).execTransactionFromModule(
            address(usdc),
            0,
            abi.encodeCall(usdc.approve, (address(glpManager), usdcAmt)),
            Enum.Operation.Call
        );

        (address to, uint256 value, bytes memory callData) = GLPController
            .depositUSDC(usdcAmt / 2);
        GnosisSafe(msg.sender).execTransactionFromModule(
            to,
            value,
            callData,
            Enum.Operation.Call
        );

        // Aave Position
        GnosisSafe(msg.sender).execTransactionFromModule(
            address(usdc),
            0,
            abi.encodeCall(usdc.approve, (address(aavePool), usdcAmt / 2)),
            Enum.Operation.Call
        );
        GnosisSafe(msg.sender).execTransactionFromModule(
            address(aavePool),
            0,
            abi.encodeCall(
                aavePool.supply,
                (address(usdc), usdcAmt / 2, address(this), 0)
            ),
            Enum.Operation.Call
        );

        uint256 wbtcAmt = ((usdcAmt / 2) * 1e2 * 1e8) / (10000 * 1e8);

        GnosisSafe(msg.sender).execTransactionFromModule(
            address(aavePool),
            0,
            abi.encodeCall(
                aavePool.borrow,
                (address(wbtc), wbtcAmt, 2, 0, address(this))
            ),
            Enum.Operation.Call
        );
    }

    modifier onlySafe() {
        require(registeredSafes[msg.sender], "only safe");
        _;
    }
}

contract GLPRiskManager {}
