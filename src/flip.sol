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

pragma solidity >=0.5.0;

import "./lib.sol";

contract VatLike {
    function move(address,address,uint) public;
    function flux(bytes32,address,address,uint) public;
}

/*
   This thing lets you flip some gems for a given amount of dai.
   Once the given amount of dai is raised, gems are forgone instead.

 - `lot` gems for sale
 - `tab` total dai wanted
 - `bid` dai paid
 - `gal` receives dai income
 - `urn` receives gem forgone
 - `ttl` single bid lifetime
 - `beg` minimum bid increase
 - `end` max auction duration
*/

contract Flipper is DSNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) public note auth { wards[guy] = 1; }
    function deny(address guy) public note auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- Data ---
    struct Bid {
        uint256 bid;
        uint256 lot;
        address guy;  // high bidder
        uint48  tic;  // expiry time
        uint48  end;
        address urn;
        address gal;
        uint256 tab;
    }

    mapping (uint => Bid) public bids;

    VatLike public   vat;
    bytes32 public   ilk;

    uint256 constant ONE = 1.00E27;
    uint256 public   beg = 1.05E27;  // 5% minimum bid increase
    uint48  public   ttl = 3 hours;  // 3 hours bid duration
    uint48  public   tau = 2 days;   // 2 days total auction length
    uint256 public kicks = 0;
    uint256 public live;

    // --- Events ---
    event Kick(
      uint256 id,
      uint256 lot,
      uint256 bid,
      uint256 tab,
      address indexed urn,
      address indexed gal
    );

    // --- Init ---
    constructor(address vat_, bytes32 ilk_) public {
        vat = VatLike(vat_);
        ilk = ilk_;
        wards[msg.sender] = 1;
        live = 1;
    }

    // --- Math ---
    function add(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    // --- Administration ---
    function cage() public note auth {
        live = 0;
    }

    // --- Auction ---
    function kick(address urn, address gal, uint tab, uint lot, uint bid)
        public note returns (uint id)
    {
        require(kicks < uint(-1));
        id = ++kicks;

        bids[id].bid = bid;
        bids[id].lot = lot;
        bids[id].guy = msg.sender; // configurable??
        bids[id].end = add(uint48(now), tau);
        bids[id].urn = urn;
        bids[id].gal = gal;
        bids[id].tab = tab;

        vat.flux(ilk, msg.sender, address(this), lot);

        emit Kick(id, lot, bid, tab, urn, gal);
    }
    function tick(uint id) public note {
        require(bids[id].end < now);
        require(bids[id].tic == 0);
        bids[id].end = add(uint48(now), tau);
    }
    function tend(uint id, uint lot, uint bid) public note {
        require(bids[id].guy != address(0));
        require(bids[id].tic > now || bids[id].tic == 0);
        require(bids[id].end > now);

        require(lot == bids[id].lot);
        require(bid <= bids[id].tab);
        require(bid >  bids[id].bid);
        require(mul(bid, ONE) >= mul(beg, bids[id].bid) || bid == bids[id].tab);

        vat.move(msg.sender, bids[id].guy, bids[id].bid);
        vat.move(msg.sender, address(this), bid - bids[id].bid);

        bids[id].guy = msg.sender;
        bids[id].bid = bid;
        bids[id].tic = add(uint48(now), ttl);
    }
    function dent(uint id, uint lot, uint bid) public note {
        require(bids[id].guy != address(0));
        require(bids[id].tic > now || bids[id].tic == 0);
        require(bids[id].end > now);

        require(bid == bids[id].bid);
        require(bid == bids[id].tab);
        require(lot < bids[id].lot);
        require(mul(beg, lot) <= mul(bids[id].lot, ONE));

        vat.move(msg.sender, bids[id].guy, bid);
        vat.flux(ilk, address(this), bids[id].urn, bids[id].lot - lot);

        bids[id].guy = msg.sender;
        bids[id].lot = lot;
        bids[id].tic = add(uint48(now), ttl);
    }
    function deal(uint id) public note {
        require(live == 1 || bids[id].bid == bids[id].tab);
        require(bids[id].tic != 0 && (bids[id].tic < now || bids[id].end < now));
        vat.move(address(this), bids[id].gal, bids[id].bid);
        vat.flux(ilk, address(this), bids[id].guy, bids[id].lot);
        delete bids[id];
    }
    function yank(uint id) public note auth {
        require(live == 0);
        require(bids[id].guy != address(0));
        require(bids[id].bid < bids[id].tab);
        vat.move(address(this), bids[id].guy, bids[id].bid);
        vat.flux(ilk, address(this), msg.sender, bids[id].lot);
        delete bids[id];
    }
}
