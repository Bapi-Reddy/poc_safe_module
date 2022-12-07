# poc_safe_module

## Summary

A poc implementation of safe module, that takes a delta neutral(dn) position with glp and shorting proportional amounts on aave.
It uses gelato tasks to maintain healthfactor at safe levels and rebalance the delta netural positions by adjusting short position on aave.

## InitPosition Flow

1. Refuels gelato
2. Rebalance task created on gelato
3. Open's position on GLP and stakes GLP for fee rewards.
4. Open's position on aave by shorting both WBTC, WETH.

Sample InitPosition Txn https://arbiscan.io/tx/0x8e3de2842670bdb68b6ec8e2b87aba9ca8ead460d4227d46468d0fb86be27c14

## Rebalance Flow

1. Resolver checks for aave health factor is within the hard limit
2. If not, it returns calldata to repay the debt of aave via funds in safe.
3. SafeModule execs rebalance operation on safe to achieve the dn position.
