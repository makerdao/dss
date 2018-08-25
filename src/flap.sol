/// flap.sol -- Surplus auction

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

contract PieLike {
    function move(bytes32,bytes32,int)  public;
}

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

contract Flapper is DSNote {
    // --- Data ---
    struct Bid {
        uint256 bid;
        uint256 lot;
        address guy;  // high bidder
        uint48  tic;  // expiry time
        uint48  end;
        address gal;
    }

    mapping (uint => Bid) public bids;

    PieLike  public   pie;
    GemLike  public   gem;

    uint256  constant ONE = 1.00E27;
    uint256  public   beg = 1.05E27;  // 5% minimum bid increase
    uint48   public   ttl = 3 hours;  // 3 hours bid duration
    uint48   public   tau = 1 weeks;  // 1 week total auction length

    uint256  public   kicks;

    function era() public view returns (uint48) { return uint48(now); }

    // --- Events ---
    event Kick(
      uint256 indexed id,
      uint256 lot,
      uint256 bid,
      address gal,
      uint48  end
    );

    // --- Init ---
    constructor(address pie_, address gem_) public {
        pie = PieLike(pie_);
        gem = GemLike(gem_);
    }

    // --- Math ---
    function mul(uint x, uint y) internal pure returns (int z) {
        z = int(x * y);
        require(int(z) >= 0);
        require(y == 0 || uint(z) / y == x);
    }

    // --- Auction ---
    function kick(address gal, uint lot, uint bid)
        public returns (uint)
    {
        uint id = ++kicks;

        bids[id].bid = bid;
        bids[id].lot = lot;
        bids[id].guy = msg.sender; // configurable??
        bids[id].end = era() + tau;
        bids[id].gal = gal;

        pie.move(bytes32(msg.sender), bytes32(address(this)), mul(lot, ONE));

        emit Kick(id, lot, bid, gal, bids[id].end);

        return id;
    }
    function tend(uint id, uint lot, uint bid) public note {
        require(bids[id].guy != 0);
        require(bids[id].tic > era() || bids[id].tic == 0);
        require(bids[id].end > era());

        require(lot == bids[id].lot);
        require(bid >  bids[id].bid);
        require(mul(bid, ONE) >= mul(beg, bids[id].bid));

        gem.move(msg.sender, bids[id].guy, bids[id].bid);
        gem.move(msg.sender, bids[id].gal, bid - bids[id].bid);

        bids[id].guy = msg.sender;
        bids[id].bid = bid;
        bids[id].tic = era() + ttl;
    }
    function deal(uint id) public note {
        require(bids[id].tic < era() && bids[id].tic != 0 ||
                bids[id].end < era());
        pie.move(bytes32(address(this)), bytes32(bids[id].guy), mul(bids[id].lot, ONE));
        delete bids[id];
    }
}
