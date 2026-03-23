// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PredictionMarket.sol";

contract DeployPredictionMarket is Script {
    PredictionMarket pm;

    function setUp() public {}

    function run() public {
        vm.createSelectFork("https://sepolia.base.org");
        vm.createSelectFork("sepolia.base.org");
        vm.startBroadcast();
        pm = new PredictionMarket();
        vm.stopBroadcast();
    }
}
