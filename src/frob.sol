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

import "ds-note/note.sol";

contract VatLike {
    function debt() public view returns (uint);
    function ilks(bytes32) public view returns (uint,uint);
    function urns(bytes32,bytes32) public view returns (uint,uint);
    function tune(bytes32,bytes32,bytes32,bytes32,int,int) public;
}

contract Dripper {
    function drip(bytes32) public;
}

contract Pit is DSNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) public note auth { wards[guy] = 1;  }
    function deny(address guy) public note auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _;  }

    // --- Data ---
    struct Ilk {
        uint256  spot;  // Price with Safety Margin, ray
        uint256  line;  // Debt Ceiling, wad
    }
    mapping (bytes32 => Ilk) public ilks;

    uint256 public live;  // Access Flag
    uint256 public Line;  // Debt Ceiling
    VatLike public  vat;  // CDP Engine
    Dripper public drip;  // Stability Fee Calculator

    // --- Events ---
    event Frob(
      bytes32 indexed ilk,
      bytes32 indexed lad,
      uint256 ink,
      uint256 art,
      int256  dink,
      int256  dart,
      uint256 iArt
    );

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        live = 1;
    }

    // --- Math ---
    uint256 constant ONE = 10 ** 27;

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    function file(bytes32 what, address data) public note auth {
        if (what == "drip") drip = Dripper(data);
    }
    function file(bytes32 what, uint data) public note auth {
        if (what == "Line") Line = data;
    }
    function file(bytes32 ilk, bytes32 what, uint data) public note auth {
        if (what == "spot") ilks[ilk].spot = data;
        if (what == "line") ilks[ilk].line = data;
    }

    // --- CDP Owner Interface ---
    function frob(bytes32 ilk, int dink, int dart) public {
        drip.drip(ilk);
        bytes32 lad = bytes32(msg.sender);
        VatLike(vat).tune(ilk, lad, lad, lad, dink, dart);

        (uint rate, uint Art) = vat.ilks(ilk);
        (uint ink,  uint art) = vat.urns(ilk, lad);
        bool calm = mul(Art, rate) <= mul(ilks[ilk].line, ONE)
                    &&  vat.debt() <= mul(Line, ONE);
        bool safe = mul(ink, ilks[ilk].spot) >= mul(art, rate);

        require(live == 1);
        require(rate != 0);
        require((calm || dart <= 0) && (dart <= 0 && dink >= 0 || safe));

        emit Frob(ilk, lad, ink, art, dink, dart, Art);
    }
}
