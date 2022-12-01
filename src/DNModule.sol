// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ICurveGauge.sol";

import "./GLPController.sol";

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

contract DNModule {
    mapping(address => bool) public registeredSafes;

    function registerSafe() public {
        require(!registeredSafes[msg.sender], "already safe");
        registeredSafes[msg.sender] = true;
    }

    function initPostion(uint256 usdcAmt) public onlySafe {
        // usdc.approve(address(glpManager), usdcAmount);

        GnosisSafe(msg.sender).execTransactionFromModule(
            address(usdc),
            0,
            abi.encodeCall(usdc.approve, (address(glpManager), usdcAmount)),
            Enum.Operation.Call
        );

        (address to, uint256 value, bytes memory callData) = GLPController
            .depositUSDC(usdcAmt / 2);
        GnosisSafe(msg.sender).execTransactionFromModule(
            to,
            value,
            data,
            Enum.Operation.Call
        );
    }

    modifier onlySafe() {
        require(registeredSafes[msg.sender], "only safe");
        _;
    }
}
