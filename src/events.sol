// Copyright (C) 2018 AGPL

pragma solidity ^0.4.23;

contract Events {

  // --- Dai Events ---

  event Dai(
    address src,
    address dst,
    int256 rad,
    bytes32 act
  );

  // --- Gem Events ---

  event Gem(
    address src,
    address dst,
    int256  wad,
    bytes32 act
  );

  // --- Admin Events ---

  event FileIlk(
    bytes32 ilk,  // urn.ilk
    bytes32 what, // risk param
    uint256 risk  // value
  );

  event FileAddr(
    bytes32 what, // risk param
    address addr  // auction address
  );

  event FileInt(
    bytes32 what, // risk param
    uint256 risk  // value
  );

  event FileUint(
    bytes32 what, // risk param
    uint256 risk  // value
  );

  // --- CDP Events ---

  event Frob(
    bytes32 ilk,  // urn.ilk
    address guy,  // msg.sender
    int256  dink, // ink delta
    int256  dart, // art delta
    uint256 ink,  // urn.ink
    uint256 art,  // urn.art
    uint48  era   // timestamp
  );

  event Bite(
    bytes32 ilk, // urn.ilk
    address guy, // urn owner
    uint256 ink, // urn.ink
    uint256 art, // urn.art
    uint48  era, // timestamp
    uint256 tab, // outstanding debt
    uint256 flip // flips[] index
  );

  // --- Auction Events ---

  event FlipKick(
    uint256 id,  // bid id
    address vat, // vat address
    bytes32 ilk, // ilk address
    uint256 lot, // gem amount
    uint256 bid, // pie amount
    address guy, // high bidder (taker)
    address gal, // receives auction income
    uint48  end, // auction end
    uint48  era, // timestamp
    address lad, // cdp owner
    uint256 tab  // pie wanted
  );

  event FlopKick(
    uint256 id,  // bid id
    address pie, // pie address
    address gem, // gem address
    uint256 lot, // gem amount
    uint256 bid, // pie amount
    address guy, // high bidder (taker)
    address vow, // msg.sender
    uint48  end, // auction end
    uint48  era  // timestamp
  );

  event FlapKick(
    uint256 id,  // bid id
    address pie, // pie address
    address gem, // gem address
    uint256 lot, // pie amount
    uint256 bid, // gem amount
    address guy, // high bidder (taker)
    address gal, // receives auction income
    uint48  end, // auction end
    uint48  era  // timestamp
  );

  event Tend(
    uint256 id,  // bid id
    uint256 lot, // lot amount
    uint256 bid, // bid amount
    address guy, // high bidder (taker)
    uint48  tic, // bid expiry
    uint48  era  // timestamp
  );

  event Dent(
    uint256 id,  // bid id
    uint256 lot, // lot amount
    uint256 bid, // bid amount
    address guy, // high bidder (taker)
    uint48  tic, // bid expiry
    uint48  era  // timestamp
  );

  event Deal(
    uint256 id,  // bid id
    uint48  era  // timestamp
  );

}
