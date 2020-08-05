/// cat.sol -- Dai liquidation module

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

pragma solidity >=0.5.12;

import "./lib.sol";

interface Kicker {
    function kick(address urn, address gal, uint tab, uint lot, uint bid)
        external returns (uint);
}

interface VatLike {
    function ilks(bytes32) external view returns (
        uint256 Art,  // [wad]
        uint256 rate, // [ray]
        uint256 spot  // [ray]
    );
    function urns(bytes32,address) external view returns (
        uint256 ink,  // [wad]
        uint256 art   // [wad]
    );
    function grab(bytes32,address,address,address,int,int) external;
    function hope(address) external;
    function nope(address) external;
}

interface VowLike {
    function fess(uint) external;
}

contract Cat is LibNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Cat/not-authorized");
        _;
    }

    // --- Data ---
    struct Ilk {
        address flip;  // Liquidator
        uint256 chop;  // Liquidation Penalty  [ray]
        uint256 lump;  // Liquidation Quantity [wad]
    }

    mapping (bytes32 => Ilk) public ilks;

    uint256 public box;    // Max Dai out for liquidation        [rad]
    uint256 public litter; // Balance of Dai out for liquidation [rad]
    uint256 public live;   // Active Flag
    VatLike public vat;    // CDP Engine
    VowLike public vow;    // Debt Engine

    // --- Events ---
    event Bite(
      bytes32 indexed ilk,
      address indexed urn,
      uint256 ink,
      uint256 art,
      uint256 tab,
      address flip,
      uint256 id
    );

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        box = 10 * MLN * RAD;
        live = 1;
    }

    // --- Math ---
    uint constant MLN = 10 **  6;
    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;
    uint constant RAD = 10 ** 45;

    function min(uint x, uint y) internal pure returns (uint z) {
        if (x > y) { z = y; } else { z = x; }
    }
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, y) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, y) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, WAD) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, RAY) / y;
    }

    // --- Administration ---
    function file(bytes32 what, address data) external note auth {
        if (what == "vow") vow = VowLike(data);
        else revert("Cat/file-unrecognized-param");
    }
    function file(bytes32 what, uint data) external note auth {
        if (what == "box") box = data;
        else revert("Cat/file-unrecognized-param");
    }
    function file(bytes32 ilk, bytes32 what, uint data) external note auth {
        if (what == "chop") ilks[ilk].chop = data;
        else if (what == "lump") ilks[ilk].lump = data;
        else revert("Cat/file-unrecognized-param");
    }
    function file(bytes32 ilk, bytes32 what, address flip) external note auth {
        if (what == "flip") {
            vat.nope(ilks[ilk].flip);
            ilks[ilk].flip = flip;
            vat.hope(flip);
        }
        else revert("Cat/file-unrecognized-param");
    }

    // --- CDP Liquidation ---
    function bite(bytes32 ilk, address urn) external returns (uint id) {
        // NOTE: because of stack-depth limits, we need to re-use num in this
        // function.  At the start, num is spot, then later becomes lot.

        (, uint rate, uint spot) = vat.ilks(ilk);
        (uint ink, uint art) = vat.urns(ilk, urn);

        require(live == 1, "Cat/not-live");
        require(spot > 0 && mul(ink, spot) < mul(art, rate), "Cat/not-unsafe");
        require(litter < box, "Cat/liquidation-limit-hit");

        Ilk memory ilkS = ilks[ilk];

        uint lot = min(ink, ilkS.lump);
        art = min(art, mul(lot, art) / ink);

        //
        //       ([box - litter] / chop)
        // art = ----------------------
        //               rate
        //
        // Pick a fractional art that doesn't put us over box
        uint fart = min(
            art, rdiv((sub(box, litter) / ilkS.chop), rate)
      //WAD=WAD, WAD       RAD, RAD     / RAY            / RAY
        );
        lot = min(lot, wmul(lot, wdiv(fart, art)));
      //WAD       WAD, WAD

        require(lot <= 2**255 && fart <= 2**255, "Cat/overflow");
        vat.grab(ilk, urn, address(this), address(vow), -int(lot), -int(fart));

        // Accumulate litter in the box
        uint tab = rmul(mul(fart, rate), ilkS.chop);
        litter = add(litter, tab);
      //RAD          RAD   , RAD  RAD WAD , RAY  , RAY

        vow.fess(mul(fart, rate));
        id = Kicker(ilkS.flip).kick({
            urn: urn,
            gal: address(vow),
            tab: tab,
            lot: lot,
            bid: 0
        });

        emit Bite(ilk, urn, lot, fart, mul(fart, rate), ilkS.flip, id);
    }

    function scoop(uint poop) external note auth {
        litter = sub(litter, poop);
    }

    function cage() external note auth {
        live = 0;
    }
}
