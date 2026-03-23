// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PredictionMarket is Ownable, ReentrancyGuard {
    uint256 public constant BET_PRICE = 0.01 ether;
    uint256 public constant HOUSE_CUT_BPS = 500; // 5%
    uint256 public constant MIN_BETS = 10; // require at least 10 bets before resolve

    uint256 public marketCounter;

    // Per-market data stored in separate mappings for easy access
    mapping(uint256 => string) public marketQuestion;
    mapping(uint256 => uint256) public marketEndTime;
    mapping(uint256 => uint256) public marketResolveTime;
    mapping(uint256 => uint256) public marketTotalYes;
    mapping(uint256 => uint256) public marketTotalNo;
    mapping(uint256 => bool) public marketResolved;
    mapping(uint256 => bool) public marketWinningOutcome;

    mapping(uint256 => mapping(address => Bet)) public bets; // marketId => user => Bet

    struct Bet {
        uint256 yesAmount;
        uint256 noAmount;
        bool claimed;
    }

    event MarketCreated(uint256 indexed marketId, string question, uint256 endTime, uint256 resolveTime);
    event BetPlaced(uint256 indexed marketId, address indexed bettor, bool outcome, uint256 amount);
    event MarketResolved(uint256 indexed marketId, bool winningOutcome);
    event Claimed(uint256 indexed marketId, address indexed bettor, uint256 amount);

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    function createMarket(string memory question, uint256 endTime, uint256 resolveTime) external onlyOwner returns (uint256) {
        require(endTime > block.timestamp, "endTime too soon");
        require(resolveTime > endTime, "resolveTime after end");
        marketCounter++;
        marketQuestion[marketCounter] = question;
        marketEndTime[marketCounter] = endTime;
        marketResolveTime[marketCounter] = resolveTime;
        emit MarketCreated(marketCounter, question, endTime, resolveTime);
        return marketCounter;
    }

    function placeBet(uint256 marketId, bool outcome) external payable nonReentrant {
        require(msg.value == BET_PRICE, "Incorrect bet amount");
        require(block.timestamp < marketEndTime[marketId], "Betting closed");
        require(!marketResolved[marketId], "Market resolved");

        Bet storage b = bets[marketId][msg.sender];
        if (outcome) {
            marketTotalYes[marketId] += msg.value;
            b.yesAmount += msg.value;
        } else {
            marketTotalNo[marketId] += msg.value;
            b.noAmount += msg.value;
        }
        emit BetPlaced(marketId, msg.sender, outcome, msg.value);
    }

    function resolveMarket(uint256 marketId, bool _winningOutcome) external onlyOwner {
        require(block.timestamp >= marketResolveTime[marketId], "Too early");
        require(!marketResolved[marketId], "Already resolved");
        uint256 total = marketTotalYes[marketId] + marketTotalNo[marketId];
        require(total >= BET_PRICE * MIN_BETS, "Not enough bets");

        marketResolved[marketId] = true;
        marketWinningOutcome[marketId] = _winningOutcome;
        emit MarketResolved(marketId, _winningOutcome);
    }

    function claim(uint256 marketId) external nonReentrant {
        Bet storage b = bets[marketId][msg.sender];
        require(b.yesAmount > 0 || b.noAmount > 0, "No bet");
        require(marketResolved[marketId], "Not resolved");
        require(!b.claimed, "Already claimed");

        bool isWinner = (marketWinningOutcome[marketId] && b.yesAmount > 0) || (!marketWinningOutcome[marketId] && b.noAmount > 0);
        require(isWinner, "Not a winner");

        uint256 totalPool = marketTotalYes[marketId] + marketTotalNo[marketId];
        uint256 houseCut = (totalPool * HOUSE_CUT_BPS) / 10000;
        uint256 winnerPayout;
        if (marketWinningOutcome[marketId]) {
            winnerPayout = (b.yesAmount * (totalPool - houseCut)) / marketTotalYes[marketId];
        } else {
            winnerPayout = (b.noAmount * (totalPool - houseCut)) / marketTotalNo[marketId];
        }

        b.claimed = true;
        (bool ok, ) = msg.sender.call{value: winnerPayout}("");
        require(ok, "Transfer failed");
        emit Claimed(marketId, msg.sender, winnerPayout);
    }

    function emergencyWithdraw() external onlyOwner {
        (bool ok, ) = owner().call{value: address(this).balance}("");
        require(ok, "Withdraw failed");
    }

    function marketCount() external view returns (uint256) { return marketCounter; }
}
