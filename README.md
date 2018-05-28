## Dai v2

Extra things since the last update.

### Adapters

Token wrappers are one solution to the need to standardise collateral
behaviour in Dai. Inconsistent decimals and transfer semantics are
reasons for wrapping.

A wrapper creates a secondary fully transferrable token. Dai v2 instead
introduces the concept of *adapters*. Rather than creating a secondary
token, we set a simple user balance and manipulate it directly within
the system.

`join` and `exit` are the regular token entry points.

Adapters should be very small and well defined contracts. Adapters are
potentially very powerful and should be carefully vetted by MKR holders.

An example adapter can be seen in `join.sol`. This adapter would work
with DSTokens, which are well behaved. Note that the only pairing
between an `ilk` and a `gem` is made in the adapter, meaning an ilk
could have multiple equivalent gems.


### Dai20 Frontend

There is no separate Dai token, nor is the core ERC20 compliant. Rather,
the core stores the minimal information for a token, user balances, and
exposes a balance transfer method `move`, which is only callable by
specified frontends. 

Similar to adapters, Dai frontends should be small and carefully vetted
as they require write-access to user balances.  An example of an ERC20
interface is provided in `transferFrom.sol`.


### Fixed Lot Size

The `lump` is the globally configured fixed lot size. `flop` and `flap`
will only happen with `lump` Dai as the buy or sell amount,
respectively.

`flip` of a CDP with debt smaller than `lump` will start an auction
attempting to cover the full debt. Larger CDPs can be partially flipped,
in quantities of `lump`.

A candidate value for `lump` might be 10,000 Dai.


### Sin Queue

`bite` starts two auctions: the collateral auction `flip` and the debt
auction `flop`. Both of these are demanding of Dai, leading to a concern
that liquidation of a large CDP may absorb all available Dai supply.

To address this concern we introduce `sin`, a queue of debts to cover,
and only allow these debts to go to auction after some time period,
`wait`, which could be 1 week.

In addition, the collateral auction does not start immediately but only
after calling `flip`.


### Missing features

1. Authentication. This code currently has no caller
   checks and should absolutely not be used in production.

2. Global settlement. A prototype of global settlement exists, but needs
   to be adapted to the current code.

3. Rate accumulation. The rate accumulator is left as an exercise for
   the reader, with the code behaving as if rates are all 0%.

4. Fully safe math.

5. Administration. There are some opinionated constants in the code,
   particularly in the auctions. These should be configurable.
