// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@gnosis.pm/safe-contracts/contracts/base/Module.sol";


contract CustomModule is Module {
    /// @dev Address that this module will pass transactions to.
    address public target;

    function customMethod(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public returns (bool success) {
        /// TO-DO: Add restrictions here

        success = GnosisSafe(target).execTransactionFromModule(
            to,
            value,
            data,
            operation
        );
        return success;
    }
}
