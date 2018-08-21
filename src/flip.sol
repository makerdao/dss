/// flip.sol -- Collateral auction

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.4.24;

contract VatLike {
    function move(bytes32,bytes32,uint)         public;
    function flux(bytes32,bytes32,bytes32,int)  public;
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

    uint constant ONE = 10 ** 18;
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
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

        vat.flux(ilk, bytes32(msg.sender), bytes32(address(this)), int(lot));

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
        require(mul(bid, ONE) >= mul(beg, bids[id].bid) || bid == bids[id].tab);

        vat.move(bytes32(msg.sender), bytes32(bids[id].guy), bids[id].bid);
        vat.move(bytes32(msg.sender), bytes32(bids[id].gal), bid - bids[id].bid);

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
        require(mul(beg, lot) <= mul(bids[id].lot, ONE));

        vat.move(bytes32(msg.sender), bytes32(bids[id].guy), bid);
        vat.flux(ilk, bytes32(address(this)), bytes32(bids[id].lad), int(bids[id].lot - lot));

        bids[id].guy = msg.sender;
        bids[id].lot = lot;
        bids[id].tic = era() + ttl;
    }
    function deal(uint id) public {
        require(bids[id].tic < era() && bids[id].tic != 0 ||
                bids[id].end < era());
        vat.flux(ilk, bytes32(address(this)), bytes32(bids[id].guy), int(bids[id].lot));
        delete bids[id];
    }
}
