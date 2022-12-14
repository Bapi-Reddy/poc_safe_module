// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "./GelatoManager.sol";
import {Registry} from "./Registry.sol";
import {AaveController} from "./AaveController.sol";

contract TaskDemo is GelatoManager, Ownable, AaveController {
    mapping(address => bytes32) public safeTask;

    bool execTasks = false;

    event SafeRebalanceExecuted(address safe);

    constructor(address ops) GelatoManager(ops) {}

    function rebalanceCheck(address safe)
        public
        view
        returns (bool, bytes memory)
    {
        if (safeTask[safe] == bytes32(0))
            return (false, "Safe is not registered");
        bool condition = AaveController.getHealthFactor(safe)< safeFactor;
        return (condition, abi.encodeCall(this.rebalanceSafe, (safe)));
    }

    /// this function should be present in safe module
    /// it may also check msgsender to be dedicatedMsgSender
    function rebalanceSafe(address safe) external onlyDedicatedMsgSender {
        // Repaying aave debt
        uint wbtcAmt = wbtc.balanceOf(safe);
        uint wethAmt = weth.balanceOf(safe);    
        AaveController.repayBTC(wbtcAmt);
        AaveController.repayETH(wethAmt);
        emit SafeRebalanceExecuted(safe);
    }

    function registerSafe(address safe) internal {
        require(safeTask[safe] == bytes32(0), "Safe already registered");
        bytes memory resolverCalldata = abi.encodeCall(
            this.rebalanceCheck,
            (safe)
        );
        // bytes memory funcSelector = bytes(this.actionForSafe.selector);
        bytes32 taskId = init(
            resolverCalldata,
            abi.encode(this.rebalanceSafe.selector)
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

    function addFunds(uint256 wad) internal {
        usdc.approve(address(ops.taskTreasury()), wad);
        _depositFunds(wad, address(usdc));
    }

    function removeFunds(uint256 wad) public onlyOwner {
        taskTreasury.withdrawFunds(payable(address(this)), address(usdc), wad);
    }

    function recover() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "recovery failed");
    }

    function exit(address safe) public onlyOwner {
        removeSafe(safe);

        uint256 bal = ITaskTreasuryUpgradable(ops.taskTreasury())
            .userTokenBalance(address(this), address(usdc));

        removeFunds(bal);
        recover();
    }

    receive() external payable {}
}
