// Copyright (C) 2018 AGPL

pragma solidity ^0.4.23;

contract LogEvents {

  // Dai transfers
  event Move(
    address src,
    address dst,
    uint256 wad
  );

  // Dai mints (drip, frob)
  event Mint(
    address dst, // receiver
    int256  wad, // pie amount
    int256  pie, // updated receiver pie balance
    uint256 Tab, // updated total supply
    uint48  era  // timestamp
  );

  // Dai burns (flog)
  event Burn(
    address src, // burner
    uint256 wad, // pie amount
    int256  pie, // updated receiver pie balance
    uint256 Tab, // updated total supply
    uint48  era  // timestamp
  );

  // CDP State change
  event Frob(
    bytes32 ilk, // urn.ilk
    address lad, // urn.lad
    uint256 gem, // urn.gem
    uint256 ink, // urn.ink
    uint256 art, // urn.art
    uint256 Art, // ilk.art
    uint48  era  // timestamp
  );

  // CDP Liquidation
  event Bite(
    bytes32 ilk,  // urn.ilk
    address lad,  // urn.lad
    uint256 ink,  // urn.ink
    uint256 art,  // urn.art
    uint256 tab,  // outstanding debt
    uint256 Art,  // ilk.Art
    uint256 flip, // flips[flip] index
    uint256 sin,  // sin[era] amount
    uint48  era   // sin[era] index
  );

  // Collateral auction start
  event FlipKick(
    uint256 id,  // bid id
    address mom, // auction contract address
    address pie, // pie address
    address gem, // gem address
    uint256 lot, // gem amount
    uint256 bid, // pie amount
    address guy, // high bidder (taker)
    address gal, // receives auction income
    uint48  end, // auction end
    uint48  era, // timestamp
    address lad, // cdp owner
    uint256 tab  // pie wanted
  );

  // Surplus auction start
  event FlapKick(
    uint256 id,  // bid id
    address mom, // auction contract address
    address pie, // pie address
    address gem, // gem address
    uint256 lot, // pie amount
    uint256 bid, // gem amount
    address guy, // high bidder (taker)
    address gal, // receives auction income
    uint48  end, // auction end
    uint48  era  // timestamp
  );

  // Debt auction start
  event FlopKick(
    uint256 id,  // bid id
    address mom, // auction contract address
    address pie, // pie address
    address gem, // gem address
    uint256 lot, // gem amount
    uint256 bid, // pie amount
    address guy, // high bidder (taker)
    address gal, // receives auction income
    uint48  end, // auction end
    uint48  era  // timestamp
  );

  // New tend phase bid
  event Tend(
    uint256 id,  // bid id
    uint256 lot, // lot amount
    uint256 bid, // bid amount
    address guy, // high bidder (taker)
    uint48  tic, // bid expiry
    uint48  era  // timestamp
  );

  // New dent phase bid
  event Dent(
    uint256 id,  // bid id
    uint256 lot, // lot amount
    uint256 bid, // bid amount
    address guy, // high bidder (taker)
    uint48  tic, // bid expiry
    uint48  era  // timestamp
  );

  // Auction settlement
  event Deal(
    uint256 id,
    uint48  era
  );

}
