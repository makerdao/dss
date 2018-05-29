// Copyright (C) 2018 AGPL

pragma solidity ^0.4.23;

contract GemLike {
    function move(address,address,uint) public;
}

/*
   This thing lets you sell some pie in return for gems.

 - `lot` pie for sale
 - `bid` gems paid
 - `gal` receives gem income
 - `ttl` single bid lifetime
 - `beg` minimum bid increase
 - `end` max auction duration
*/


contract Flapper {
    GemLike public pie;
    GemLike public gem;

    uint256 public beg = 1.05 ether;  // 5% minimum bid increase
    uint48  public ttl = 3.00 hours;  // 3 hours bid lifetime
    uint48  public tau = 1 weeks;     // 1 week total auction length

    uint256 public kicks;

    struct Bid {
        uint256 bid;
        uint256 lot;
        address guy;  // high bidder
        uint48  tic;  // time of last bid
        uint48  end;
        address gal;
    }

    mapping (uint => Bid) public bids;

    function era() public view returns (uint48) { return uint48(now); }

    uint constant WAD = 10 ** 18;
    function mul(uint x, uint y) internal pure returns (uint z) {
        require((y == 0 || x * y / y == x) && (z = x * y + WAD / 2) >= x * y);
        z = z / WAD;
    }

    constructor(address pie_, address gem_) public {
        pie = GemLike(pie_);
        gem = GemLike(gem_);
    }

    function kick(address gal, uint lot, uint bid)
        public returns (uint)
    {
        uint id = ++kicks;
        pie.move(msg.sender, this, lot);

        bids[id].bid = bid;
        bids[id].lot = lot;
        bids[id].guy = msg.sender; // configurable??
        bids[id].end = era() + tau;
        bids[id].gal = gal;

        return id;
    }
    function tend(uint id, uint lot, uint bid) public {
        require(bids[id].guy != 0);
        require(bids[id].tic > era() || bids[id].tic == 0);
        require(bids[id].end > era());

        require(lot == bids[id].lot);
        require(bid >= mul(beg, bids[id].bid));

        gem.move(msg.sender, this, bid);
        gem.move(this, bids[id].gal, bid - bids[id].bid);
        gem.move(this, bids[id].guy, bids[id].bid);

        bids[id].guy = msg.sender;
        bids[id].bid = bid;
        bids[id].tic = era() + ttl;
    }
    function deal(uint id) public {
        require(bids[id].tic < era() && bids[id].tic != 0 ||
                bids[id].end < era());
        pie.move(this, bids[id].guy, bids[id].lot);
        delete bids[id];
    }
}
