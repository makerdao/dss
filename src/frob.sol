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

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "ds-note/note.sol";

contract VatLike {
    struct Ilk {
        uint256 take;  // ray
        uint256 rate;  // ray
        uint256 Ink;   // wad
        uint256 Art;   // wad
    }
    struct Urn {
        uint256 ink;   // wad
        uint256 art;   // wad
    }
    function debt() public view returns (uint);
    function ilks(bytes32) public view returns (Ilk memory);
    function urns(bytes32,bytes32) public view returns (Urn memory);
    function tune(bytes32,bytes32,bytes32,bytes32,int,int) public;
}

contract Pit is DSNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) public note auth { wards[guy] = 1; }
    function deny(address guy) public note auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- Data ---
    struct Ilk {
        uint256  spot;  // Price with Safety Margin  [ray]
        uint256  line;  // Debt Ceiling              [wad]
    }
    mapping (bytes32 => Ilk) public ilks;

    uint256 public live;  // Access Flag
    uint256 public Line;  // Debt Ceiling  [wad]
    VatLike public  vat;  // CDP Engine

    // --- Events ---
    event Frob(
      bytes32 indexed ilk,
      bytes32 indexed urn,
      uint256 ink,
      uint256 art,
      int256  dink,
      int256  dart,
      uint256 iInk,
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
    function file(bytes32 what, uint data) public note auth {
        if (what == "Line") Line = data;
    }
    function file(bytes32 ilk, bytes32 what, uint data) public note auth {
        if (what == "spot") ilks[ilk].spot = data;
        if (what == "line") ilks[ilk].line = data;
    }

    // --- CDP Owner Interface ---
    function frob(bytes32 ilk, int dink, int dart) public {
        frob(ilk, bytes32(bytes20(msg.sender)), dink, dart);
    }
    function frob(bytes32 ilk, bytes32 urn, int dink, int dart) public {
        VatLike(vat).tune(ilk, urn, urn, urn, dink, dart);

        VatLike.Ilk memory i = vat.ilks(ilk);
        VatLike.Urn memory u = vat.urns(ilk, urn);

        bool calm = mul(i.Art, i.rate) <= mul(ilks[ilk].line, ONE)
                         && vat.debt() <= mul(Line, ONE);
        bool cool = dart <= 0;
        bool firm = dink >= 0;
        bool safe = mul(u.ink, ilks[ilk].spot) >= mul(u.art, i.rate);

        require((calm || cool) && (cool && firm || safe));
        require(msg.sender == address(bytes20(urn)));
        require(i.rate != 0);
        require(live == 1);

        emit Frob(ilk, urn, u.ink, u.art, dink, dart, i.Ink, i.Art);
    }
}
