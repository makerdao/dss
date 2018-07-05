// Copyright (C) 2018 AGPL

pragma solidity ^0.4.24;

contract GemLike {
    function move(address,address,uint) public;
}

contract VatLike {
    function move(address,address,uint) public;
    function slip(bytes32,address,int)  public;
}


/*
   This thing lets you flip some gems for a given amount of pie.
   Once the given amount of pie is raised, gems are forgone instead.

 - `lot` gems for sale
 - `tab` total pie wanted
 - `bid` pie paid
 - `gal` receives pie income
 - `lad` receives gem forgone
 - `ttl` single bid lifetime
 - `beg` minimum bid increase
 - `end` max auction duration
*/

contract Flipper {
    VatLike public vat;
    bytes32 public ilk;

    uint256 public beg = 1.05 ether;  // 5% minimum bid increase
    uint48  public ttl = 3.00 hours;  // 3 hours bid duration
    uint48  public tau = 1 weeks;     // 1 week total auction length

    uint256 public kicks;

    struct Bid {
        uint256 bid;
        uint256 lot;
        address guy;  // high bidder
        uint48  tic;  // expiry time
        uint48  end;
        address lad;
        address gal;
        uint256 tab;
    }

    mapping (uint => Bid) public bids;

    function era() public view returns (uint48) { return uint48(now); }

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    uint constant WAD = 10 ** 18;
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    constructor(address vat_, bytes32 ilk_) public {
        ilk = ilk_;
        vat = VatLike(vat_);
    }

    function kick(address lad, address gal, uint tab, uint lot, uint bid)
        public returns (uint)
    {
        uint id = ++kicks;

        bids[id].bid = bid;
        bids[id].lot = lot;
        bids[id].guy = msg.sender; // configurable??
        bids[id].end = era() + tau;
        bids[id].lad = lad;
        bids[id].gal = gal;
        bids[id].tab = tab;

        return id;
    }
    function tick(uint id) public {
        require(bids[id].end < era());
        require(bids[id].tic == 0);
        bids[id].end = era() + tau;
    }
    function tend(uint id, uint lot, uint bid) public {
        require(bids[id].guy != 0);
        require(bids[id].tic > era() || bids[id].tic == 0);
        require(bids[id].end > era());

        require(lot == bids[id].lot);
        require(bid <= bids[id].tab);
        require(bid >  bids[id].bid);
        require(bid >= wmul(beg, bids[id].bid) || bid == bids[id].tab);

        vat.move(msg.sender, bids[id].guy, bids[id].bid);
        vat.move(msg.sender, bids[id].gal, bid - bids[id].bid);

        bids[id].guy = msg.sender;
        bids[id].bid = bid;
        bids[id].tic = era() + ttl;
    }
    function dent(uint id, uint lot, uint bid) public {
        require(bids[id].guy != 0);
        require(bids[id].tic > era() || bids[id].tic == 0);
        require(bids[id].end > era());

        require(bid == bids[id].bid);
        require(bid == bids[id].tab);
        require(lot < bids[id].lot);
        require(wmul(beg, lot) <= bids[id].lot);

        vat.move(msg.sender, bids[id].guy, bid);
        vat.slip(ilk, bids[id].lad, int(bids[id].lot - lot));

        bids[id].guy = msg.sender;
        bids[id].lot = lot;
        bids[id].tic = era() + ttl;
    }
    function deal(uint id) public {
        require(bids[id].tic < era() && bids[id].tic != 0 ||
                bids[id].end < era());
        vat.slip(ilk, bids[id].guy, int(bids[id].lot));
        delete bids[id];
    }
}
