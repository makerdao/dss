// SPDX-License-Identifier: AGPL-3.0-or-later

/// clap.sol -- Surplus auction

// Copyright (C) 2021 Dai Foundation
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

pragma solidity >=0.5.12;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

interface VatLike {
    function move(address,address,uint256) external;
}

interface GemLike {
    function burn(address,uint256) external;
}

interface PipLike {
    function peek() external returns (bytes32, bool);
}

interface SpotterLike {
    function par() external returns (uint256);
}

interface ClapperCallee {
    function clapperCall(address, uint256, uint256, bytes calldata) external;
}

interface AbacusLike {
    function price(uint256, uint256) external view returns (uint256);
}

/*
   This thing lets you sell some dai in return for gems.

 - `lot` dai in return for bid
 - `bid` gems paid
 - `ttl` single bid lifetime
 - `beg` minimum bid increase
 - `end` max auction duration
*/

contract Clapper {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "Clapper/not-authorized");
        _;
    }

    // --- Data ---
    struct Sale {
        uint256 lot;    // dai to sell          [rad]
        uint256 dip; // Starting price       [ray]
        uint48  tic;    // Auction start time   [timestamp]
    }

    mapping (uint256 => Sale) public sales;

    VatLike     public immutable vat;   // CDP Engine
    GemLike     public immutable gem;
    address     public vow;
    address     public spotter;
    address     public pip;
    AbacusLike  public calc;            // Current price calculator

    uint256 public buf;    // Multiplicative factor to decrease starting price                  [ray]
    uint256 public tail;   // Time elapsed before auction reset                                 [seconds]
    uint256 public cusp;   // Percentage increment before auction reset                         [ray]

    uint256  public kicks;
    uint256  public live;  // Active Flag

    uint256 internal locked;

    // Levels for circuit breaker
    // 0: no breaker
    // 1: no new kick()
    // 2: no new kick() or redo()
    // 3: no new kick(), redo(), or take()
    uint256 public stopped = 0;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);

    event Kick(
      uint256 indexed id,
      uint256 lot,
      uint256 dip
    );
    event Take(
        uint256 indexed id,
        uint256 min,
        uint256 price,
        uint256 lot,
        uint256 slice
    );
    event Redo(
        uint256 indexed id,
        uint256 lot,
        uint256 dip
    );

    // event Yank(uint256 id);

    // --- Init ---
    constructor(address vat_, address gem_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        gem = GemLike(gem_);
        live = 1;
    }

    modifier lock {
        require(locked == 0, "Clapper/system-locked");
        locked = 1;
        _;
        locked = 0;
    }

    modifier isStopped(uint256 level) {
        require(stopped < level, "Clapper/stopped-incorrect");
        _;
    }

    // --- Math ---
    uint256 constant BLN = 10 **  9;
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / RAY;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, RAY) / y;
    }

    // --- Admin ---
    function file(bytes32 what, uint256 data) external auth {
        if      (what == "buf")         buf = data;
        else if (what == "tail")       tail = data;           // Time elapsed before auction reset
        else if (what == "cusp")       cusp = data;           // Percentage increment before auction reset
        else revert("Clapper/file-unrecognized-param");
        emit File(what, data);
    }

    function file(bytes32 what, address data) external auth lock {
        if (what == "spotter") spotter = data;
        else if (what == "pip")    pip = data;
        else if (what == "vow")    vow = data;
        else if (what == "calc")  calc = AbacusLike(data);
        else revert("Clapper/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Auction ---
    function kick(
        uint256 lot,
        uint256 // For compatibility with actual vow
    ) external auth lock isStopped(1) returns (uint256 id) {
        require(live == 1, "Clapper/not-live");
        require(kicks < uint256(-1), "Clapper/overflow");
        id = ++kicks;

        sales[id].lot = lot;
        sales[id].tic = uint48(block.timestamp);
        uint256 dip = rmul(getFeedPrice(), buf);
        require(dip > 0, "Clapper/zero-dip-price");
        sales[id].dip = dip;

        vat.move(msg.sender, address(this), lot);

        emit Kick(id, lot, dip);
    }

    function redo(
        uint256 id  // id of the auction to reset
    ) external lock isStopped(2) {
        uint256 lot   = sales[id].lot;
        require(lot > 0, "Clapper/not-running-auction");

        (bool done,) = status(sales[id].tic, sales[id].dip);
        require(done, "Clapper/cannot-reset");
        
        sales[id].tic = uint48(block.timestamp);

        uint256 dip = rmul(getFeedPrice(), buf);
        require(dip > 0, "Clapper/zero-dip-price");
        sales[id].dip = dip;

        emit Redo(id, lot, dip);
    }

    function take(
        uint256 id,
        uint256 lot,
        uint256 min,
        address who,
        bytes calldata data
    ) external lock isStopped(3) {
        require(live == 1, "Clapper/not-live");
        require(sales[id].lot > 0, "Clapper/not-running-auction");

        uint48 tic = sales[id].tic;
        (bool done, uint256 price) = status(tic, sales[id].dip);
        require(!done, "Clapper/needs-reset");

        require(lot <= sales[id].lot, "Clapper/lot-not-matching");
        require(min < price, "Clapper/bid-not-higher");

        sales[id].lot -= lot;

        // TODO: Add dust check for remaining lot

        vat.move(address(this), who, lot);

        uint256 slice = lot / price;

        if (data.length > 0 && who != address(vat) && who != address(this)) {
            ClapperCallee(who).clapperCall(msg.sender, lot, slice, data);
        }

        gem.burn(msg.sender, slice);

        emit Take(id, min, price, lot, slice);
    }

    function cage(
        uint256 rad
    ) external auth {
       live = 0;
       vat.move(address(this), msg.sender, rad);
    }

    function getFeedPrice() internal returns (uint256 feedPrice) {
        (bytes32 val, bool has) = PipLike(pip).peek();
        require(has, "Clapper/invalid-price");
        feedPrice = rdiv(mul(uint256(val), BLN), SpotterLike(spotter).par());
    }

    // Externally returns boolean for if an auction needs a redo and also the current price
    function getStatus(uint256 id) external view returns (bool needsRedo, uint256 price, uint256 lot) {
        bool done;
        (done, price) = status(sales[id].tic, sales[id].dip);
        lot = sales[id].lot;
        needsRedo = lot > 0 && done;
    }

    // Internally returns boolean for if an auction needs a redo
    function status(uint96 tic, uint256 dip) internal view returns (bool done, uint256 price) {
        price = calc.price(dip, sub(block.timestamp, tic));
        done  = (sub(block.timestamp, tic) > tail || rdiv(price, dip) > cusp);
    }
}
