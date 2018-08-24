/// bite.sol -- Dai liquidation module

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

import "src/events.sol";

contract Flippy{
    function kick(bytes32 lad, address gal, uint tab, uint lot, uint bid)
        public returns (uint);
}

contract VatLike {
    function ilks(bytes32) public view returns (uint,uint);
    function urns(bytes32,bytes32) public view returns (uint,uint);
    function grab(bytes32,bytes32,bytes32,bytes32,int,int) public returns (uint);
}

contract PitLike {
    function ilks(bytes32) public view returns (uint,uint);
}

contract VowLike {
    function fess(uint) public;
}

contract Cat is Events {
    address public vat;
    address public pit;
    address public vow;
    uint256 public lump;  // fixed lot size

    mapping (address => bool) public wards;
    function rely(address guy) public auth { wards[guy] = true;  }
    function deny(address guy) public auth { wards[guy] = false; }
    modifier auth { require(wards[msg.sender]); _;  }

    struct Ilk {
        uint256 chop;
        address flip;
    }
    mapping (bytes32 => Ilk) public ilks;

    struct Flip {
        bytes32 ilk;
        bytes32 lad;
        uint256 ink;
        uint256 tab;
    }

    uint256                   public nflip;
    mapping (uint256 => Flip) public flips;

    constructor(address vat_, address pit_, address vow_) public {
        wards[msg.sender] = true;
        vat = vat_;
        pit = pit_;
        vow = vow_;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
    }

    uint constant RAY = 10 ** 27;
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / RAY;
    }

    function file(bytes32 what, uint risk) public auth {
        if (what == "lump") lump = risk;
    }
    function file(bytes32 ilk, bytes32 what, uint risk) public auth {
        if (what == "chop") ilks[ilk].chop = risk;
    }
    function fuss(bytes32 ilk, address flip) public auth {
        ilks[ilk].flip = flip;
    }

    function bite(bytes32 ilk, bytes32 guy) public returns (uint) {
        (uint rate, uint Art)           = VatLike(vat).ilks(ilk); Art;
        (uint spot, uint line)          = PitLike(pit).ilks(ilk); line;
        (uint ink , uint art) = VatLike(vat).urns(ilk, guy);
        uint tab = rmul(art, rate);

        require(rmul(ink, spot) < tab);  // !safe

        VatLike(vat).grab(ilk, guy, bytes32(address(this)), bytes32(vow), -int(ink), -int(art));
        VowLike(vow).fess(uint(tab));

        flips[nflip] = Flip(ilk, guy, uint(ink), uint(tab));

        emit Bite(ilk, guy, ink, art, uint48(now), tab, nflip);

        return nflip++;
    }

    function flip(uint n, uint wad) public returns (uint) {
        Flip storage f = flips[n];
        Ilk  storage i = ilks[f.ilk];

        require(wad <= f.tab);
        require(wad == lump || (wad < lump && wad == f.tab));

        uint tab = f.tab;
        uint ink = mul(f.ink, wad) / tab;

        f.tab -= wad;
        f.ink -= ink;

        return Flippy(i.flip).kick({ lad: f.lad
                                   , gal: vow
                                   , tab: uint(rmul(wad, i.chop))
                                   , lot: uint(ink)
                                   , bid: uint(0)
                                   });
    }
}
