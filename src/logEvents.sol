// Copyright (C) 2018 AGPL

pragma solidity ^0.4.23;

contract LogEvents {

  // CDP State change
  event LogFrob(
    bytes32 ilk, // urn.ilk
    address lad, // urn.lad
    uint256 gem, // urn.gem
    uint256 ink, // urn.ink
    uint256 art, // urn.art
    uint256 Art, // ilk.art
    uint48  era  // timestamp
  );

  // CDP Liquidation
  event LogBite(
    bytes32 ilk,  // urn.ilk
    address lad,  // urn.lad
    uint256 ink,  // urn.ink
    uint256 art,  // urn.art
    uint256 tab,  // outstanding debt
    uint256 Art,  // ilk.Art
    uint256 flip, // flips[flip] index
    uint48  era   // sin[era] timestamp
  );

  // Collateral auction start
  event LogFlipKick(
    uint256 id,  // bid id
    address mom, // auction contract address
    address pie, // pie address
    address gem, // gem address
    uint256 lot, // gem amount
    uint256 bid, // pie amount
    address guy, // high bidder (taker)
    address gal, // receives auction income
    uint48  end, // auction end
    uint48  now, // event timestamp
    address lad, // cdp owner
    uint256 tab  // pie wanted
  );

  // Surplus auction start
  event LogFlapKick(
    uint256 id,  // bid id
    address mom, // auction contract address
    address pie, // pie address
    address gem, // gem address
    uint256 lot, // pie amount
    uint256 bid, // gem amount
    address guy, // high bidder (taker)
    address gal, // receives auction income
    uint48  end, // auction end
    uint48  now  // event timestamp
  );

  // Debt auction start
  event LogFlopKick(
    uint256 id,  // bid id
    address mom, // auction contract address
    address pie, // pie address
    address gem, // gem address
    uint256 lot, // gem amount
    uint256 bid, // pie amount
    address guy, // high bidder (taker)
    address gal, // receives auction income
    uint48  end, // auction end
    uint48  now  // event timestamp
  );

  // New tend phase bid
  event LogTend(
    uint256 id,  // bid id
    uint256 bid, // bid amount
    address guy, // high bidder (taker)
    uint48  tic, // bid expiry
    uint48  now  // event timestamp
  );

  // New dent phase bid
  event LogDent(
    uint256 id,  // bid id
    uint256 lot, // lot amount
    address guy, // high bidder (taker)
    uint48  tic, // bid expiry
    uint48  now  // event timestamp
  );

  // Auction settlement
  event LogDeal(
    uint256 id,
    uint48 now
  );

}
