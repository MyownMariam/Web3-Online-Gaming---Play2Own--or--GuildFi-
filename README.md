# 🎮 Web3 Gaming - Play2Own / GuildFi

A decentralized gaming platform built on Stacks blockchain that enables true player ownership through NFTs, tournaments, DAO governance, and DeFi yield farming.

## 🌟 Features

### 🏆 NFT Game Assets
- **True Ownership**: Players own their game items as NFTs
- **Cross-Game Compatibility**: Assets can be transferred between players
- **Rarity System**: Items have different power levels and rarities
- **Metadata Support**: Rich asset information storage

### ⚔️ Tournament System
- **Entry Fees**: Players pay guild tokens to join tournaments
- **Prize Pools**: Winners take the entire tournament prize pool
- **Player Limits**: Configurable maximum players per tournament
- **Active Management**: Only contract owner can declare winners

### 🏛️ DAO Governance
- **Proposal Creation**: Token holders can create game improvement proposals
- **Voting Power**: Vote weight based on guild token holdings
- **Time-Limited Voting**: Proposals have expiration blocks
- **Democratic Process**: Community shapes game development

### 💰 DeFi Loot Pools
- **Yield Farming**: Stake guild tokens to earn passive rewards
- **Block-Based Rewards**: Earn rewards proportional to staking duration
- **Compound Growth**: Rewards automatically compound over time
- **Flexible Staking**: Stake additional tokens anytime

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://docs.hiro.so/stacks/clarinet) installed
- Stacks wallet for testing

### Installation
```bash
git clone <repository-url>
cd Web3-Online-Gaming---Play2Own--or--GuildFi-
clarinet check
```

### Testing
```bash
npm install
npm test
```

## 📖 Usage Guide

### 🎯 For Players

#### Mint Game Assets
Only contract owner can mint new game assets:
```clarity
(contract-call? .contract mint-asset 'SP1... "Legendary Sword" "legendary" u100 "rpg")
```

#### Join Tournaments
```clarity
(contract-call? .contract join-tournament u1)
```

#### Stake in Loot Pools
```clarity
(contract-call? .contract stake-in-loot-pool u1000)
```

#### Claim Rewards
```clarity
(contract-call? .contract claim-loot-rewards)
```

### 🏛️ For DAO Participants

#### Create Proposals
```clarity
(contract-call? .contract create-dao-proposal "Balance Update" "Increase sword damage by 10%" u144)
```

#### Vote on Proposals
```clarity
(contract-call? .contract vote-on-proposal u1 true)
```

### 👑 For Game Administrators

#### Create Tournaments
```clarity
(contract-call? .contract create-tournament "Weekly Championship" u100 u16 u1008)
```

#### Declare Winners
```clarity
(contract-call? .contract declare-winner u1 'SP1...)
```

#### Mint Guild Tokens
```clarity
(contract-call? .contract mint-guild-tokens 'SP1... u1000)
```

## 🔍 Contract Functions

### 📝 Public Functions
- `mint-asset`: Create new game NFTs
- `transfer-asset`: Transfer NFTs between players
- `create-tournament`: Set up new tournaments
- `join-tournament`: Enter tournaments with entry fees
- `declare-winner`: Award tournament prizes
- `stake-in-loot-pool`: Stake tokens for yield
- `claim-loot-rewards`: Collect staking rewards
- `create-dao-proposal`: Submit governance proposals
- `vote-on-proposal`: Vote on community proposals
- `mint-guild-tokens`: Issue new guild tokens

### 👀 Read-Only Functions
- `get-asset-metadata`: View NFT properties
- `get-tournament-info`: Check tournament details
- `get-loot-pool-info`: View staking information
- `get-dao-proposal`: Read proposal details
- `get-asset-owner`: Find NFT owner
- `has-voted`: Check if user voted on proposal
- `is-tournament-player`: Verify tournament participation

## 🎮 Game Economy

### 💎 Guild Tokens
- **Utility Token**: Used for all platform interactions
- **Governance Rights**: Voting power in DAO decisions
- **Tournament Entry**: Required to join competitions
- **Staking Rewards**: Earn yield through loot pools

### 🏺 NFT Assets
- **Unique Items**: Each asset has distinct properties
- **Power Levels**: Numerical strength values
- **Rarity Tiers**: Common, rare, epic, legendary classifications
- **Game Types**: Assets categorized by game genre

## 🛡️ Security Features

- **Access Control**: Owner-only functions for sensitive operations
- **Input Validation**: Comprehensive error handling
- **Balance Checks**: Prevents insufficient fund transactions
- **Double-Spend Protection**: Prevents duplicate votes and tournament entries

## 📊 Error Codes

| Code | Error | Description |
|------|--------|-------------|
| u100 | ERR-NOT-AUTHORIZED | Caller lacks required permissions |
| u101 | ERR-INVALID-TOKEN | Token ID doesn't exist |
| u102 | ERR-TOURNAMENT-NOT-FOUND | Tournament ID invalid |
| u103 | ERR-ALREADY-JOINED | Player already in tournament |
| u104 | ERR-TOURNAMENT-FULL | Tournament at capacity |
| u105 | ERR-TOURNAMENT-ENDED | Tournament no longer active |
| u106 | ERR-INSUFFICIENT-FUNDS | Not enough tokens |
| u107 | ERR-PROPOSAL-NOT-FOUND | Proposal ID invalid |
| u108 | ERR-ALREADY-VOTED | User already voted on proposal |

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes and test
4. Submit pull request

## 📄 License

MIT License - see LICENSE file for details

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/references/language-clarity)
- [Clarinet Developer Tools](https://docs.hiro.so/stacks/clarinet)

---

**Built with ❤️ for the Web3 gaming community** 🚀
