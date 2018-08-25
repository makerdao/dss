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

import "ds-note/note.sol";

contract VatLike {
    function move(bytes32,bytes32,int)         public;
    function flux(bytes32,bytes32,bytes32,int) public;
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

contract Flipper is DSNote {
    // --- Data ---
    struct Bid {
        uint256 bid;
        uint256 lot;
        address guy;  // high bidder
        uint48  tic;  // expiry time
        uint48  end;
        bytes32 lad;
        address gal;
        uint256 tab;
    }

    mapping (uint => Bid) public bids;

    VatLike public   vat;
    bytes32 public   ilk;

    uint256 constant ONE = 1.00E27;
    uint256 public   beg = 1.05E27;  // 5% minimum bid increase
    uint48  public   ttl = 3 hours;  // 3 hours bid duration
    uint48  public   tau = 1 weeks;  // 1 week total auction length

    uint256 public   kicks;

    function era() public view returns (uint48) { return uint48(now); }

    // --- Events ---
    event Kick(
      uint256 indexed id,
      uint256 lot,
      uint256 bid,
      address gal,
      uint48  end,
      bytes32 indexed lad,
      uint256 tab
    );

    // --- Init ---
    constructor(address vat_, bytes32 ilk_) public {
        ilk = ilk_;
        vat = VatLike(vat_);
    }

    // --- Math ---
    function mul(uint x, uint y) internal pure returns (int z) {
        z = int(x * y);
        require(int(z) >= 0);
        require(y == 0 || uint(z) / y == x);
    }

    // --- Auction ---
    function kick(bytes32 lad, address gal, uint tab, uint lot, uint bid)
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

        require(int(lot) >= 0);
        vat.flux(ilk, bytes32(msg.sender), bytes32(address(this)), int(lot));

        emit Kick(id, lot, bid, gal, bids[id].end, bids[id].lad, bids[id].tab);

        return id;
    }
    function tick(uint id) public note {
        require(bids[id].end < era());
        require(bids[id].tic == 0);
        bids[id].end = era() + tau;
    }
    function tend(uint id, uint lot, uint bid) public note {
        require(bids[id].guy != 0);
        require(bids[id].tic > era() || bids[id].tic == 0);
        require(bids[id].end > era());

        require(lot == bids[id].lot);
        require(bid <= bids[id].tab);
        require(bid >  bids[id].bid);
        require(mul(bid, ONE) >= mul(beg, bids[id].bid) || bid == bids[id].tab);

        vat.move(bytes32(msg.sender), bytes32(bids[id].guy), mul(bids[id].bid, ONE));
        vat.move(bytes32(msg.sender), bytes32(bids[id].gal), mul(bid - bids[id].bid, ONE));

        bids[id].guy = msg.sender;
        bids[id].bid = bid;
        bids[id].tic = era() + ttl;
    }
    function dent(uint id, uint lot, uint bid) public note {
        require(bids[id].guy != 0);
        require(bids[id].tic > era() || bids[id].tic == 0);
        require(bids[id].end > era());

        require(bid == bids[id].bid);
        require(bid == bids[id].tab);
        require(lot < bids[id].lot);
        require(mul(beg, lot) <= mul(bids[id].lot, ONE));

        vat.move(bytes32(msg.sender), bytes32(bids[id].guy), mul(bid, ONE));
        vat.flux(ilk, bytes32(address(this)), bids[id].lad,  int(bids[id].lot - lot));

        bids[id].guy = msg.sender;
        bids[id].lot = lot;
        bids[id].tic = era() + ttl;
    }
    function deal(uint id) public note {
        require(bids[id].tic < era() && bids[id].tic != 0 ||
                bids[id].end < era());
        vat.flux(ilk, bytes32(address(this)), bytes32(bids[id].guy), int(bids[id].lot));
        delete bids[id];
    }
}
