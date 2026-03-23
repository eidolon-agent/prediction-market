// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PredictionMarket is Ownable, ReentrancyGuard {
    uint256 public constant BET_PRICE = 0.01 ether;
    uint256 public constant HOUSE_CUT_BPS = 500; // 5%
    uint256 public constant MIN_BETS = 10; // require at least 10 bets before resolve

    struct Market {
        string question;
        uint256 endTime; // betting ends at this timestamp
        uint256 resolveTime; // can be resolved after this timestamp
        uint256 totalYes;
        uint256 totalNo;
        bool resolved;
        bool winningOutcome; // true = YES, false = NO
    }

    Market[] public markets;
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
        markets.push(Market({
            question: question,
            endTime: endTime,
            resolveTime: resolveTime,
            totalYes: 0,
            totalNo: 0,
            resolved: false,
            winningOutcome: false
        }));
        uint256 id = markets.length - 1;
        emit MarketCreated(id, question, endTime, resolveTime);
        return id;
    }

    function placeBet(uint256 marketId, bool outcome) external payable nonReentrant {
        require(msg.value == BET_PRICE, "Incorrect bet amount");
        Market storage m = markets[marketId];
        require(block.timestamp < m.endTime, "Betting closed");
        require(!m.resolved, "Market resolved");

        Bet storage b = bets[marketId][msg.sender];
        if (outcome) {
            m.totalYes += msg.value;
            b.yesAmount += msg.value;
        } else {
            m.totalNo += msg.value;
            b.noAmount += msg.value;
        }
        emit BetPlaced(marketId, msg.sender, outcome, msg.value);
    }

    function resolveMarket(uint256 marketId, bool _winningOutcome) external onlyOwner {
        Market storage m = markets[marketId];
        require(block.timestamp >= m.resolveTime, "Too early");
        require(!m.resolved, "Already resolved");
        require((m.totalYes + m.totalNo) >= BET_PRICE * MIN_BETS, "Not enough bets");

        m.resolved = true;
        m.winningOutcome = _winningOutcome;
        emit MarketResolved(marketId, _winningOutcome);
    }

    function claim(uint256 marketId) external nonReentrant {
        Bet storage b = bets[marketId][msg.sender];
        require(b.yesAmount > 0 || b.noAmount > 0, "No bet");
        Market storage m = markets[marketId];
        require(m.resolved, "Not resolved");
        require(!b.claimed, "Already claimed");

        bool isWinner = (m.winningOutcome && b.yesAmount > 0) || (!m.winningOutcome && b.noAmount > 0);
        require(isWinner, "Not a winner");

        uint256 totalPool = m.totalYes + m.totalNo;
        uint256 houseCut = (totalPool * HOUSE_CUT_BPS) / 10000;
        uint256 winnerPayout;
        if (m.winningOutcome) {
            // winners split the pool minus house cut proportionally to their yes bet
            winnerPayout = (b.yesAmount * (totalPool - houseCut)) / m.totalYes;
        } else {
            winnerPayout = (b.noAmount * (totalPool - houseCut)) / m.totalNo;
        }

        b.claimed = true;
        (bool ok, ) = msg.sender.call{value: winnerPayout}("");
        require(ok, "Transfer failed");
        emit Claimed(marketId, msg.sender, winnerPayout);
    }

    // Owner can sweep excess ETH (e.g., if someone sends accidentally) after market resolved
    function emergencyWithdraw() external onlyOwner {
        (bool ok, ) = owner().call{value: address(this).balance}("");
        require(ok, "Withdraw failed");
    }

    // Views
    function marketCount() external view returns (uint256) { return markets.length; }
    function myBet(uint256 marketId) external view returns (uint256 yes, uint256 no) {
        Bet storage b = bets[marketId][msg.sender];
        return (b.yesAmount, b.noAmount);
    }
}
