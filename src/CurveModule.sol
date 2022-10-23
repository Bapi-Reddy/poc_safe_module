// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ICurveGauge.sol";

import "./Enum.sol";

interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
}

contract CurveModule {
    /// @dev Address that this module will pass transactions to.
    ICurveGauge internal curveGauge = ICurveGauge(0x9633E0749faa6eC6d992265368B88698d6a93Ac0);

    function harvest(address safe) public returns (bool success) {
        success = GnosisSafe(safe).execTransactionFromModule(
            address(curveGauge), 0, abi.encodeWithSignature("claim_rewards()"), Enum.Operation.Call
        );
        return success;
    }
}
