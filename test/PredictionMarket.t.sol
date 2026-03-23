// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/PredictionMarket.sol";

contract PredictionMarketTest is Test {
    PredictionMarket pm;

    function setUp() public {
        pm = new PredictionMarket();
    }

    function testCreateMarketAndBet() public {
        vm.prank(owner(pm));
        uint256 marketId = pm.createMarket("ETH > $3000?", block.timestamp + 1 days, block.timestamp + 2 days);
        vm.prank(address(this));
        pm.placeBet{value: 0.01 ether}(marketId, true);
        assertEq(pm.markets(marketId).totalYes, 0.01 ether);
    }

    function testResolveAndClaim() public {
        vm.prank(owner(pm));
        uint256 marketId = pm.createMarket("ETH > $3000?", block.timestamp + 1 hours, block.timestamp + 2 hours);
        // user bets YES
        vm.prank(address(this));
        pm.placeBet{value: 0.02 ether}(marketId, true);
        // fast forward to resolve time
        vm.warp(block.timestamp + 2 hours + 1);
        vm.prank(owner(pm));
        pm.resolveMarket(marketId, true); // YES wins
        // claim
        vm.prank(address(this));
        pm.claim(marketId);
        // check balance increased
    }
}

// helper to get owner
function owner(PredictionMarket c) internal pure returns (address) {
    return c.owner();
}
