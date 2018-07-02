// Copyright (C) 2018 AGPL

pragma solidity ^0.4.23;

contract LogEvents {

  event LogKick(
    uint256 id,     // bid id
    address mom,    // auction contract address
    address lotKey, // lot address
    address bidKey, // bid address
    uint256 lot,    // lot amount
    uint256 bid,    // bid amount
    address guy,    // high bidder (taker)
    address gal,    // receives auction income
    uint48  end,    // auction end
    uint48  now     // event timestamp
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
