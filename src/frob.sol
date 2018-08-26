/// frob.sol -- Dai CDP user interface

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

import './tune.sol';

contract Drip {
    function drip(bytes32) public;
}

contract Pit {
    // --- Auth ---
    mapping (address => bool) public wards;
    function rely(address guy) public auth { wards[guy] = true;  }
    function deny(address guy) public auth { wards[guy] = false; }
    modifier auth { require(wards[msg.sender]); _;  }

    // --- Data ---
    struct Ilk {
        uint256  spot;  // Price with Safety Margin, ray
        uint256  line;  // Debt Ceiling, wad
    }
    mapping (bytes32 => Ilk) public ilks;

    Vat   public  vat;  // CDP Engine
    uint  public Line;  // Debt Ceiling
    bool  public live;  // Access Flag
    Drip  public drip;  // Stability Fee Calculator

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = true;
        vat = Vat(vat_);
        live = true;
    }

    // --- Math ---
    uint256 constant ONE = 10 ** 27;

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    function file(bytes32 what, address drip_) public auth {
        if (what == "drip") drip = Drip(drip_);
    }
    function file(bytes32 what, uint risk) public auth {
        if (what == "Line") Line = risk;
    }
    function file(bytes32 ilk, bytes32 what, uint risk) public auth {
        if (what == "spot") ilks[ilk].spot = risk;
        if (what == "line") ilks[ilk].line = risk;
    }

    // --- CDP Owner Interface ---
    function frob(bytes32 ilk, int dink, int dart) public {
        drip.drip(ilk);
        bytes32 lad = bytes32(msg.sender);
        vat.tune(ilk, lad, lad, lad, dink, dart);

        (uint rate, uint Art) = vat.ilks(ilk);
        (uint ink,  uint art) = vat.urns(ilk, lad);
        bool calm = mul(Art, rate) <= mul(ilks[ilk].line, ONE) &&
                        vat.debt() <= mul(Line, ONE);
        bool safe = mul(ink, ilks[ilk].spot) >= mul(art, rate);

        require(live);
        require(rate != 0);
        require((calm || dart <= 0) && (dart <= 0 && dink >= 0 || safe));
    }
}
