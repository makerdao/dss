// Copyright (C) 2018 AGPL

// todo: case that nobody bids (maybe needs tick). who is initial guy?

pragma solidity ^0.4.24;

contract GemLike {
    function move(address,address,uint) public;
    function mint(address,uint) public;
}

contract VowLike {
    function kiss(uint) public;
}

/*
   This thing creates gems on demand in return for pie.

 - `lot` gems for sale
 - `bid` pie paid
 - `gal` receives pie income
 - `ttl` single bid lifetime
 - `beg` minimum bid increase
 - `end` max auction duration
*/

contract Flopper {
    GemLike public pie;
    GemLike public gem;

    uint256 public beg = 1.05 ether;  // 5% minimum bid increase
    uint48  public ttl = 3.00 hours;  // 3 hours bid lifetime
    uint48  public tau = 1 weeks;     // 1 week total auction length

    uint256 public kicks;

    modifier auth { _; }  // todo

    struct Bid {
        uint256 bid;
        uint256 lot;
        address guy;  // high bidder
        uint48  tic;  // expiry time
        uint48  end;
        address vow;
    }

    mapping (uint => Bid) public bids;

    function era() public view returns (uint48) { return uint48(now); }

    uint constant ONE = 1 ether;
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    constructor(address pie_, address gem_) public {
        pie = GemLike(pie_);
        gem = GemLike(gem_);
    }

    function kick(address gal, uint lot, uint bid) public auth returns (uint) {
        uint id = ++kicks;

        bids[id].vow = msg.sender;
        bids[id].bid = bid;
        bids[id].lot = lot;
        bids[id].guy = gal;
        bids[id].end = era() + tau;

        return id;
    }
    function dent(uint id, uint lot, uint bid) public {
        require(bids[id].guy != 0);
        require(bids[id].tic > era() || bids[id].tic == 0);
        require(bids[id].end > era());

        require(bid == bids[id].bid);
        require(lot <  bids[id].lot);
        require(mul(beg, lot) / ONE <= bids[id].lot);  // div as lot can be huge

        pie.move(msg.sender, bids[id].guy, bid);

        bids[id].guy = msg.sender;
        bids[id].lot = lot;
        bids[id].tic = era() + ttl;
    }
    function deal(uint id) public {
        require(bids[id].tic < era() && bids[id].tic != 0 ||
                bids[id].end < era());
        gem.mint(bids[id].guy, bids[id].lot);
        delete bids[id];
    }
}
