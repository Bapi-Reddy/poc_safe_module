// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
// import "../src/TaskDemo.sol";
import "../src/DNModule.sol";

contract TaskerScript is Script {
    function setUp() public {}

    function run() public {
        address ops = 0x527a819db1eb0e34426297b03bae11F2f8B3A19E;
        address sender = 0xAE75B29ADe678372D77A8B41225654138a7E6ff1;
        vm.startBroadcast();

        // TaskDemo td = new TaskDemo(ops);
        // payable(address(td)).call{value: 1 ether}("");
        // td.addFunds(1 ether);
        // td.registerSafe(sender);

        DNModule dn = new DNModule();

        vm.stopBroadcast();

        // td.exit(sender);

        // td.registerSafe(address(this));
    }

    fallback() external payable {}
}
