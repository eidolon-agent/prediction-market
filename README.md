# Prediction Market

Binary yes/no markets on Base Sepolia. Users bet 0.01 ETH per ticket. House takes 5% of total pool. Owner creates markets and resolves after a trusted off‑chain price feed (MVP: owner as resolver).

## Contract

- `createMarket(string question, uint256 endTime, uint256 resolveTime)` — owner only
- `placeBet(marketId, bool outcome)` — pay 0.01 ETH, choose YES/NO
- `resolveMarket(marketId, bool winningOutcome)` — owner only after resolveTime and enough bets
- `claim(marketId)` — winners claim proportional share of pool (minus house cut)

## Frontend

Static HTML in `frontend/index.html`. Deploy to Vercel (root=`frontend`). Update `CONTRACT_ADDRESS` after deployment.

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
- Contract: `0x5cF1E23bB2Ad549F0BE948Fcb02575a903B7e3de`
- Basescan: https://sepolia.basescan.org/address/0x5cF1E23bB2Ad549F0BE948Fcb02575a903B7e3de

## Roadmap

- Replace owner resolver with Chainlink or UMA price feeds
- Support custom bet amounts
- Add The Graph subgraph for market history
- Allow market creator to set fee percentage

## License

MIT
