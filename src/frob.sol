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
import './events.sol';

contract Pit is Events {
    Vat   public  vat;
    uint  public Line;
    bool  public live;

    constructor(address vat_) public { vat = Vat(vat_); live = true; }

    modifier auth { _; }  // todo

    struct Ilk {
        uint256  spot;  // ray
        uint256  line;  // wad
    }

    mapping (bytes32 => Ilk) public ilks;

    function file(bytes32 what, uint risk) public auth {
        if (what == "Line") Line = risk;

        emit FileUint(what, risk);
    }
    function file(bytes32 ilk, bytes32 what, uint risk) public auth {
        if (what == "spot") ilks[ilk].spot = risk;
        if (what == "line") ilks[ilk].line = risk;

        emit FileIlk(ilk, what, risk);
    }

    uint256 constant ONE = 10 ** 27;
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function frob(bytes32 ilk, int dink, int dart) public {
        bytes32 guy = bytes32(msg.sender);
        vat.tune(ilk, guy, guy, guy, dink, dart);

        (uint rate, uint Art) = vat.ilks(ilk);
        (uint ink,  uint art) = vat.urns(ilk, bytes32(msg.sender));
        bool calm = mul(Art, rate) <= mul(ilks[ilk].line, ONE) &&
                        vat.debt() <  mul(Line, ONE);
        bool safe = mul(ink, ilks[ilk].spot) >= mul(art, rate);

        require( ( calm || dart<=0 ) && ( dart<=0 && dink>=0 || safe ) && live);
        require(rate != 0);

        emit Frob(ilk,  msg.sender, dink, dart, ink, art, uint48(now));
    }
}
