# Prediction Market

Binary yes/no markets on Base Sepolia. Users bet 0.01 ETH per outcome. House takes 5% of total pool. Owner creates markets and resolves after a trusted off‑chain price feed (MVP: owner as resolver). Payouts are proportional to the winning side.

## Contract

- `createMarket(string question, uint256 endTime, uint256 resolveTime)` — owner only
- `placeBet(marketId, bool outcome)` — pay 0.01 ETH, choose YES/NO
- `resolveMarket(marketId, bool winningOutcome)` — owner only after resolveTime and enough bets (MIN_BETS = 10)
- `claim(marketId)` — winners claim proportional share of pool (minus house cut)
- Reentrancy‑protected (`nonReentrant`) on `claim`
- Explicit getters for all mappings to avoid ABI encoding issues: `getMarketQuestion`, `getMarketEndTime`, `getMarketResolveTime`, `getMarketTotalYes`, `getMarketTotalNo`, `getMarketResolved`, `getMarketWinningOutcome`

## Frontend

Static HTML in `frontend/index.html`. Deploy to Vercel (root=`frontend`). The contract address is already configured.

**Live frontend:** https://frontend-v77mp0zck-nikayrezzas-projects.vercel.app

Features:
- Connect wallet (MetaMask) with network guard (Base Sepolia)
- List all markets with status (Open/Closed/Resolved), pool size (ETH and USD), and odds
- Owner create market UI (question, end/resolve timestamps)
- Owner resolve market (select winner YES/NO)
- Place bet with transaction simulation before sending
- Claim prizes with simulation
- Auto‑refresh every 15 s
- Transaction status and error display

## Deploy

```bash
export BASE_SEPOLIA_RPC_URL="https://sepolia.base.org"
export PRIVATE_KEY="0x..."
forge script script/DeployPredictionMarket.s.sol:DeployPredictionMarket \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

**Deployed on Base Sepolia:**
- Contract: `0x69b14ccE71f3BB9181125B480492f5D0903A2622`
- Verification pending
- (Previous address) `0x5cF1E23bB2Ad549F0BE948Fcb02575a903B7e3de` (legacy)

## Roadmap

- Replace owner resolver with Chainlink or UMA price feeds
- Support custom bet amounts and multiple market types
- Add The Graph subgraph for market history and indexing
- Allow market creator to set fee percentage (instead of fixed 5%)
- Add off‑chain indexing for better UI responsiveness

## Tests

- `forge test` covers:
  - Market creation and validation
  - Betting (YES/NO) with exact amount
  - Resolution after sufficient bets
  - Claim flow and payout calculation
  - Reentrancy guard on `claim`

## License

MIT
