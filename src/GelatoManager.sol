// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "ops/integrations/OpsTaskCreator.sol";

contract GelatoManager is OpsTaskCreator {
    constructor(address _ops) OpsTaskCreator(_ops, address(this)) {}

    function init(bytes memory resolverCalldata, bytes memory funcSelector)
        internal
        returns (bytes32 currentTask)
    {
        ModuleData memory moduleData = ModuleData({
            modules: new Module[](3),
            args: new bytes[](3)
        });

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.TIME;
        moduleData.modules[2] = Module.PROXY;

        moduleData.args[0] = _resolverModuleArg(
            address(this), // address of resolver
            resolverCalldata // what function to call on resolver
        );
        moduleData.args[1] = _timeModuleArg(
            block.timestamp, //starttime
            300 //interval
        );
        moduleData.args[2] = _proxyModuleArg();

        currentTask = _createTask(
            address(this), // _execAddress
            funcSelector, // _execDataOrSelector
            moduleData, // _moduleData
            address(0) // _feeToken
        );
    }
}
