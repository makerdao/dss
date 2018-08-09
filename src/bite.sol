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

contract Flippy{
    function kick(address lad, address gal, uint tab, uint lot, uint bid)
        public returns (uint);
}

contract VatLike {
    function ilks(bytes32) public view returns (int,int);
    function urns(bytes32,address) public view returns (int,int,int);
    function grab(bytes32,address,address,int,int) public returns (uint);
}

contract LadLike {
    function ilks(bytes32) public view returns (int,int);
}

contract VowLike {
    function fess(uint) public;
}

contract Cat {
    address public vat;
    address public lad;
    address public vow;
    uint256 public lump;  // fixed lot size

    modifier auth { _; }  // todo

    struct Ilk {
        int256  chop;
        address flip;
    }
    mapping (bytes32 => Ilk) public ilks;

    struct Flip {
        bytes32 ilk;
        address lad;
        uint256 ink;
        uint256 tab;
    }
    Flip[] public flips;

    constructor(address vat_, address lad_, address vow_) public {
        vat = vat_;
        lad = lad_;
        vow = vow_;
    }

    function file(bytes32 what, uint risk) public auth {
        if (what == "lump") lump = risk;
    }
    function file(bytes32 ilk, bytes32 what, int risk) public auth {
        if (what == "chop") ilks[ilk].chop = risk;
    }
    function fuss(bytes32 ilk, address flip) public auth {
        ilks[ilk].flip = flip;
    }

    function bite(bytes32 ilk, address guy) public returns (uint) {
        (int rate, int Art)           = VatLike(vat).ilks(ilk); Art;
        (int spot, int line)          = LadLike(lad).ilks(ilk); line;
        (int gem , int ink , int art) = VatLike(vat).urns(ilk, guy); gem;
        int tab = rmul(art, rate);

        require(rmul(ink, spot) < tab);  // !safe

        VatLike(vat).grab(ilk, guy, vow, -ink, -art);
        VowLike(vow).fess(uint(tab));

        return flips.push(Flip(ilk, guy, uint(ink), uint(tab))) - 1;
    }

    function flip(uint n, uint wad) public returns (uint) {
        Flip storage f = flips[n];
        Ilk  storage i = ilks[f.ilk];

        require(wad <= f.tab);
        require(wad == lump || (wad < lump && wad == f.tab));

        uint tab = f.tab;
        uint ink = f.ink * wad / tab;

        f.tab -= wad;
        f.ink -= ink;

        return Flippy(i.flip).kick({ lad: f.lad
                                   , gal: vow
                                   , tab: uint(rmul(int(wad), i.chop))
                                   , lot: uint(ink)
                                   , bid: uint(0)
                                   });
    }

    int constant RAY = 10 ** 27;
    function rmul(int x, int y) internal pure returns (int z) {
        z = x * y / RAY;
    }
}
