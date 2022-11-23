// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "ops/integrations/OpsTaskCreator.sol";

contract GelatoManager is OpsTaskCreator {
    constructor(address ops) OpsTaskCreator(ops, address(this)) {}

    bytes currentTask;

    function init(address safe, bytes calldata resolverCalldata)
        internal
        returns (bytes)
    {
        require(currentTask == bytes(0), "task already present");
        ModuleData memory moduleData = ModuleData({
            modules: new Module[](3),
            args: new bytes[](3)
        });

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.TIME;
        moduleData.modules[2] = Module.PROXY;

        moduleData.args[0] = _resolverModuleArg(
            address(this),
            abi.encodeCall(this.checker, ())
        );
        moduleData.args[1] = _timeModuleArg(block.timestamp, 300);
        moduleData.args[2] = _proxyModuleArg();

        currentTask = _createTask(address(this), "", moduleData, ETH);
    }

    function kill() internal {
        _cancelTask(currentTask);
        delete (currentTask);
    }
}
