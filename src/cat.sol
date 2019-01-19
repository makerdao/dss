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

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "ds-note/note.sol";

contract Flippy {
    function kick(bytes32 urn, address gal, uint tab, uint lot, uint bid)
        public returns (uint);
    function gem() public returns (address);
}

contract Hopeful {
    function hope(address) public;
    function nope(address) public;
}

contract VatLike {
    struct Ilk {
        uint256 Art;   // wad
        uint256 rate;  // ray
        uint256 spot;  // ray
        uint256 line;  // wad
    }
    struct Urn {
        uint256 ink;   // wad
        uint256 art;   // wad
    }
    function ilks(bytes32) public view returns (Ilk memory);
    function urns(bytes32,bytes32) public view returns (Urn memory);
    function grab(bytes32,bytes32,bytes32,bytes32,int,int) public;
}

contract VowLike {
    function fess(uint) public;
}

contract Cat is DSNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) public note auth { wards[guy] = 1; }
    function deny(address guy) public note auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- Data ---
    struct Ilk {
        address flip;  // Liquidator
        uint256 chop;  // Liquidation Penalty   [ray]
        uint256 lump;  // Liquidation Quantity  [wad]
    }
    struct Flip {
        bytes32 ilk;  // Collateral Type
        bytes32 urn;  // CDP Identifier
        uint256 ink;  // Collateral Quantity [wad]
        uint256 tab;  // Debt Outstanding    [wad]
    }

    mapping (bytes32 => Ilk)  public ilks;
    mapping (uint256 => Flip) public flips;
    uint256                   public nflip;

    uint256 public live;
    VatLike public vat;
    VowLike public vow;

    // --- Events ---
    event Bite(
      bytes32 indexed ilk,
      bytes32 indexed urn,
      uint256 ink,
      uint256 art,
      uint256 tab,
      uint256 flip
    );

    event FlipKick(
      uint256 nflip,
      uint256 bid
    );

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        live = 1;
    }

    // --- Math ---
    uint constant ONE = 10 ** 27;

    function mul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / ONE;
    }

    // --- Administration ---
    function file(bytes32 what, address data) public note auth {
        if (what == "vow") vow = VowLike(data);
    }
    function file(bytes32 ilk, bytes32 what, uint data) public note auth {
        if (what == "chop") ilks[ilk].chop = data;
        if (what == "lump") ilks[ilk].lump = data;
    }
    function file(bytes32 ilk, bytes32 what, address flip) public note auth {
        if (what == "flip") ilks[ilk].flip = flip;
    }

    // --- CDP Liquidation ---
    function bite(bytes32 ilk, bytes32 urn) public returns (uint) {
        require(live == 1);
        VatLike.Ilk memory i = vat.ilks(ilk);
        VatLike.Urn memory u = vat.urns(ilk, urn);
        uint tab = rmul(u.art, i.rate);

        require(rmul(u.ink, i.spot) < tab);  // !safe

        vat.grab(ilk, urn, bytes32(bytes20(address(this))), bytes32(bytes20(address(vow))), -int(u.ink), -int(u.art));
        vow.fess(tab);

        flips[nflip] = Flip(ilk, urn, u.ink, tab);

        emit Bite(ilk, urn, u.ink, u.art, tab, nflip);

        return nflip++;
    }
    function flip(uint n, uint wad) public note returns (uint id) {
        require(live == 1);
        Flip storage f = flips[n];
        Ilk  storage i = ilks[f.ilk];

        require(wad <= f.tab);
        require(wad == i.lump || (wad < i.lump && wad == f.tab));

        uint tab = f.tab;
        uint ink = mul(f.ink, wad) / tab;

        f.tab -= wad;
        f.ink -= ink;

        Hopeful(Flippy(i.flip).gem()).hope(i.flip);
        id = Flippy(i.flip).kick({ urn: f.urn
                                 , gal: address(vow)
                                 , tab: rmul(wad, i.chop)
                                 , lot: ink
                                 , bid: 0
                                 });
        emit FlipKick(n, id);
        Hopeful(Flippy(i.flip).gem()).nope(i.flip);
    }
}
