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

contract Pit {
    Vat   public  vat;
    int   public Line;
    bool  public live;

    constructor(address vat_) public { vat = Vat(vat_); live = true; }

    modifier auth { _; }  // todo

    struct Ilk {
        int256  spot;  // ray
        int256  line;  // wad
    }

    mapping (bytes32 => Ilk) public ilks;

    function file(bytes32 what, int risk) public auth {
        if (what == "Line") Line = risk;
    }
    function file(bytes32 ilk, bytes32 what, int risk) public auth {
        if (what == "spot") ilks[ilk].spot = risk;
        if (what == "line") ilks[ilk].line = risk;
    }

    function mul(int x, int y) internal pure returns (int z) {
        z = x * y;
        require(y >= 0 || x != -2**255);
        require(y == 0 || z / y == x);
    }

    int256 constant ONE = 10 ** 27;

    function frob(bytes32 ilk, int dink, int dart) public {
        bytes32 guy = bytes32(msg.sender);
        vat.tune(ilk, guy, guy, guy, dink, dart);

        (int rate, int Art)           = vat.ilks(ilk);
        (int ink,  int art) = vat.urns(ilk, bytes32(msg.sender));
        bool calm = mul(Art, rate) <= mul(ilks[ilk].line, ONE) &&
                        vat.Tab()  <  mul(Line, ONE);
        bool safe = mul(ink, ilks[ilk].spot) >= mul(art, rate);

        require( ( calm || dart<=0 ) && ( dart<=0 && dink>=0 || safe ) && live);
        require(rate != 0);
    }
}
