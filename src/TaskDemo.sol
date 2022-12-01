// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "./GelatoManager.sol";

contract TaskDemo is GelatoManager, Ownable {
    mapping(address => bytes32) public safeTask;

    bool execTasks;

    event SafetaskDone(address safe);

    constructor(address ops) GelatoManager(ops) {}

    function toDoOrNotToDo(address safe)
        public
        view
        returns (bool, bytes memory)
    {
        if (safeTask[safe] == bytes32(0))
            return (false, "Safe is not registered");
        if (execTasks)
            return (true, abi.encodeCall(this.actionForSafe, (safe)));
        return (false, "execution not set to true");
    }

    /// this function should be present in safe module
    /// it may also check msgsender to be dedicatedMsgSender
    /// for demo, this is currently in the resolver
    function actionForSafe(address safe) external onlyDedicatedMsgSender {
        // DO whatever you need to
        emit SafetaskDone(safe);
    }

    function registerSafe(address safe) public onlyOwner {
        require(safeTask[safe] == bytes32(0), "Safe already registered");
        bytes memory resolverCalldata = abi.encodeCall(
            this.toDoOrNotToDo,
            (safe)
        );
        // bytes memory funcSelector = bytes(this.actionForSafe.selector);
        bytes32 taskId = init(
            resolverCalldata,
            abi.encode(this.actionForSafe.selector)
        );
        safeTask[safe] = taskId;
    }

    function removeSafe(address safe) public onlyOwner {
        bytes32 taskId = safeTask[safe];
        require(taskId != bytes32(0), "Safe doesnt exist");
        _cancelTask(taskId);
        delete safeTask[safe];
    }

    function flipExec() public onlyOwner {
        execTasks = !execTasks;
    }

    function addFunds(uint256 wad) public onlyOwner {
        _depositFunds(wad, ETH);
    }

    // function removeFunds(uint256 wad) public payable onlyOwner {
    //     withdrawFunds(wad, ETH);
    // }

    function recover() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "recovery failed");
    }

    // function exit(address safe) public onlyOwner {
    //     removeSafe(safe);

    //     uint256 bal = ITaskTreasuryUpgradable(ops.taskTreasury())
    //         .userTokenBalance(address(this), ETH);

    //     removeFunds(bal);
    //     recover();
    // }

    receive() external payable {}
}
