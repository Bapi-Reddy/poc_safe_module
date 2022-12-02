// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
// import "../src/TaskDemo.sol";
import "../src/DNModule.sol";

contract TaskerScript is Script {
    function setUp() public {}

    function run() public {
        address ops = 0xB3f5503f93d5Ef84b06993a1975B9D21B962892F;
        address sender = 0xAE75B29ADe678372D77A8B41225654138a7E6ff1;
        vm.startBroadcast();

        // TaskDemo td = new TaskDemo(ops);
        // payable(address(td)).call{value: 1 ether}("");
        // td.addFunds(1 ether);
        // td.registerSafe(sender);

        DNModule dn = new DNModule(ops);

        vm.stopBroadcast();

        // td.exit(sender);

        // td.registerSafe(address(this));
    }

    fallback() external payable {}
}
