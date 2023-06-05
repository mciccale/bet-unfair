# BetUnfair

**Betting platform implementation using Elixir + OTP Patterns**

## Clarification about ACID Transactions
CubDB provides an API for making transactions CubDB.transaction/2. However, we simply used CubDB.get_and_update/3 that searchs for a value and then modifies it ATOMICALLY.

## How-To

```
$ git clone https://github.com/mciccale/bet-unfair.git
$ cd bet_unfair
$ mix deps.get
```

Authors:

- Ramiro Lopez Cento
- Esteban Aspe Ruiz
- Marco Ciccale Baztan
