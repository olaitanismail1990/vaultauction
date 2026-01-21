```markdown
# Vault Auction DAO

A comprehensive Stacks smart contract implementing a decentralized auction system with integrated STX vault management, governance, and reputation tracking.

## Overview

**Vault Auction DAO** is a full-featured Clarity smart contract that combines:
- **Secure STX Vault**: Deposit and withdraw STX with balance tracking
- **Time-based Auctions**: Create and bid on auctions with block-height constraints
- **DAO Governance**: Community-controlled fee adjustments via voting
- **Reputation System**: Track user activity and bidding history
- **Treasury Management**: Collect and manage DAO fees from auction settlements

## Features

###  Vault Management
- **Deposit**: Users can deposit STX into their vault balance
- **Withdraw**: Secure withdrawal with balance validation
- Balance tracking per user with map storage

###  Auction System
- **Create Auctions**: Sellers can create time-locked auctions with configurable duration
- **Bidding**: Users can place bids with automatic bid increment validation
- **Settlement**: Automatic payout distribution and fee collection upon auction completion
- **Bid Refunds**: Previous bidders automatically receive their STX back when outbid

###  DAO Governance
- **Fee Voting**: Community members can vote on DAO fee percentages
- **Fee Updates**: Apply community-voted fee changes
- **Treasury**: Collect and track DAO fees from all auctions

###  Reputation Tracking
- Track user activity through reputation points
- Reputation increases on auction wins and sales
- Use reputation for future community features

## Contract Functions

### Public Functions

#### Vault Operations
```clarity
(deposit amount: uint) -> (ok bool)
```
Deposit STX into your vault. Transfers amount from caller to contract.

```clarity
(withdraw amount: uint) -> (ok bool | err)
```
Withdraw STX from vault. Returns error if insufficient balance.

#### Auction Operations
```clarity
(create-auction starting-bid: uint, duration: uint) -> (ok uint | err)
```
Create a new auction. Returns auction ID on success.

```clarity
(bid auction-id: uint, amount: uint) -> (ok bool | err)
```
Place a bid on an active auction. Must have sufficient vault balance and bid higher than current highest bid.

```clarity
(settle-auction auction-id: uint) -> (ok bool | err)
```
Settle a completed auction. Distributes funds to seller (minus DAO fee) and updates reputation.

#### DAO Governance
```clarity
(vote-fee new-fee: uint) -> (ok bool)
```
Vote for a new DAO fee percentage (in basis points, e.g., 25 = 2.5%).

```clarity
(apply-fee new-fee: uint) -> (ok bool | err)
```
Apply a voted fee change. Caller must have voted for this fee.

### Read-Only Functions

```clarity
(get-vault user: principal) -> uint
```
Get vault balance for a specific user. Returns 0 if no balance.

```clarity
(get-reputation user: principal) -> uint
```
Get reputation points for a specific user.

```clarity
(get-auction auction-id: uint) -> (optional {...})
```
Get full auction details including seller, bidders, and settlement status.

## Data Structures

### Auction Map Entry
```clarity
{
  seller: principal,           ;; Auction creator
  highest-bidder: principal?,  ;; Current highest bidder (optional)
  highest-bid: uint,           ;; Current highest bid amount
  end-block: uint,             ;; Block height when auction ends
  settled: bool                ;; Settlement status
}
```

## Error Codes

| Code | Constant | Meaning |
|------|----------|---------|
| u1 | ERR-AUTH | Authentication/Authorization failed |
| u2 | ERR-NOT-FOUND | Auction or resource not found |
| u3 | ERR-STATE | Invalid contract state (auction expired, already settled, etc.) |
| u4 | ERR-BALANCE | Insufficient vault balance |

## Configuration

### Default Parameters
- **DAO Fee**: 2.5% (25 basis points)
- **Treasury**: Starts at 0, accumulates from auction fees

## Usage Example

### 1. Deposit STX
```
(contract-call? .vaultauction deposit u1000000)
```

### 2. Create an Auction
```
(contract-call? .vaultauction create-auction u500000 u144)
;; Creates auction with 500,000 STX starting bid, 144 block duration (~1 hour)
```

### 3. Place a Bid
```
(contract-call? .vaultauction bid u1 u600000)
;; Bid 600,000 STX on auction #1
```

### 4. Settle Auction
```
(contract-call? .vaultauction settle-auction u1)
;; Settle auction #1 after block height expires
```

### 5. Vote on Fees
```
(contract-call? .vaultauction vote-fee u30)
;; Vote for 3% DAO fee
```

## Security Considerations

- ✅ All STX transfers are validated and wrapped in try! blocks
- ✅ Balance checks prevent overdrafts
- ✅ Block-height validation prevents settled auctions from modification
- ✅ Optional bidders handled safely with unwrap-panic
- ⚠️ DAO fee application requires prior vote (basic governance check)

## Gas Optimization

- Maps used for O(1) lookups instead of lists
- Minimal computation per function call
- Efficient fee calculation using integer division

## Contract Compatibility

- **Clarity Version**: 3.0+
- **Network**: Stacks 2.0+
- **Framework**: Clarinet

## Testing

Run tests with Clarinet:
```bash
clarinet test
```

## Future Enhancements

- [ ] Multi-signature auction creation
- [ ] Auction categories/collections
- [ ] Reputation-based bidding limits
- [ ] Escrow integration
- [ ] Auction extensions on last-minute bids
- [ ] Advanced governance with staking

## License

[Specify your license here - e.g., MIT, Apache 2.0]

## Support

For issues, questions, or contributions, please open an issue or submit a pull request.

---
 
**Contract Version**: 1.0.0  
**Status**: Production Ready ✅
