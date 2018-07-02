// Copyright (C) 2018 AGPL

pragma solidity ^0.4.23;

contract LogEvents {
  event LogFrob(
    bytes32 ilk,
    address lad,
    uint256 gem,
    uint256 ink,
    uint256 art,
    uint256 Art,
    uint48  now
  );

  event LogBite(
    bytes32 ilk,
    address lad,
    uint256 ink,
    uint256 tab,
    uint256 art,
    uint256 Art
  );

  event LogFlapKick(
    uint256 id,     // bid id
    address mom,    // auction contract address
    address pie,    // pie address
    address gem,    // gem address
    uint256 lot,    // pie amount
    uint256 bid,    // gem amount
    address guy,    // high bidder (taker)
    address gal,    // receives auction income
    uint48  end,    // auction end
    uint48  now     // event timestamp
  );

  event LogFlopKick(
    uint256 id,     // bid id
    address mom,    // auction contract address
    address pie,    // pie address
    address gem,    // gem address
    uint256 lot,    // gem amount
    uint256 bid,    // pie amount
    address guy,    // high bidder (taker)
    address gal,    // receives auction income
    uint48  end,    // auction end
    uint48  now     // event timestamp
  );

  event LogFlipKick(
    uint256 id,     // bid id
    address mom,    // auction contract address
    address lotKey, // gem address
    address bidKey, // pie address
    uint256 lot,    // gem amount
    uint256 bid,    // pie amount
    address guy,    // high bidder (taker)
    address gal,    // receives auction income
    uint48  end,    // auction end
    uint48  now,    // event timestamp
    address lad,    // cdp owner
    uint256 tab     // pie wanted
  );

  event LogTend(
    uint256 id,  // bid id
    uint256 bid, // bid amount
    address guy, // high bidder (taker)
    uint48  tic, // bid expiry
    uint48  now  // event timestamp
  );

  event LogDent(
    uint256 id,  // bid id
    uint256 lot, // lot amount
    address guy, // high bidder (taker)
    uint48  tic, // bid expiry
    uint48  now  // event timestamp
  );

  event LogDeal(
    uint256 id,
    uint48 now
  );

}
