/// flop.sol -- Debt auction

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

contract GemLike {
    function move(address,address,uint) public;
    function mint(address,uint) public;
}

/*
   This thing creates gems on demand in return for dai.

 - `lot` gems for sale
 - `bid` dai paid
 - `gal` receives dai income
 - `ttl` single bid lifetime
 - `beg` minimum bid increase
 - `end` max auction duration
*/

contract Flopper is DSNote {
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
        address vow;
    }

    mapping (uint => Bid) public bids;

    GemLike  public   dai;
    GemLike  public   gem;

    uint256  constant ONE = 1.00E27;
    uint256  public   beg = 1.05E27;  // 5% minimum bid increase
    uint48   public   ttl = 3 hours;  // 3 hours bid lifetime
    uint48   public   tau = 2 days;   // 2 days total auction length

    uint256  public   kicks;

    // --- Events ---
    event Kick(
      uint256 indexed id,
      uint256 lot,
      uint256 bid,
      address gal,
      uint48  end
    );

    // --- Init ---
    constructor(address dai_, address gem_) public {
        wards[msg.sender] = 1;
        dai = GemLike(dai_);
        gem = GemLike(gem_);
    }

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x);
    }
    function mul(uint x, uint y) internal pure returns (int z) {
        z = int(x * y);
        require(int(z) >= 0);
        require(y == 0 || uint(z) / y == x);
    }

    // --- Auction ---
    function kick(address gal, uint lot, uint bid) public auth returns (uint id) {
        require(kicks < uint(-1));
        id = ++kicks;

        bids[id].vow = msg.sender;
        bids[id].bid = bid;
        bids[id].lot = lot;
        bids[id].guy = gal;
        bids[id].end = uint48(add(now, tau));

        emit Kick(id, lot, bid, gal, bids[id].end);
    }
    function dent(uint id, uint lot, uint bid) public note {
        require(bids[id].guy != 0);
        require(bids[id].tic > now || bids[id].tic == 0);
        require(bids[id].end > now);

        require(bid == bids[id].bid);
        require(lot <  bids[id].lot);
        require(uint(mul(beg, lot)) / ONE <= bids[id].lot);  // div as lot can be huge

        dai.move(msg.sender, bids[id].guy, bid);

        bids[id].guy = msg.sender;
        bids[id].lot = lot;
        bids[id].tic = uint48(add(now, ttl));
    }
    function deal(uint id) public note {
        require(bids[id].tic < now && bids[id].tic != 0 ||
                bids[id].end < now);
        gem.mint(bids[id].guy, bids[id].lot);
        delete bids[id];
    }
}
