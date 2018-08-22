/// tune.sol -- Dai CDP database

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

contract Vat {
    modifier auth { _; }  // todo

    struct Ilk {
        uint256  rate;  // ray
        uint256  Art;   // wad
    }
    struct Urn {
        uint256 ink;    // wad
        uint256 art;    // wad
    }

    mapping (bytes32 => Ilk)                       public ilks;
    mapping (bytes32 => mapping (bytes32 => Urn )) public urns;
    mapping (bytes32 => mapping (bytes32 => uint)) public gem;    // wad
    mapping (bytes32 => uint256)                   public dai;    // rad
    mapping (bytes32 => uint256)                   public sin;    // rad

    uint256  public debt;   // rad
    uint256  public vice;  // rad

    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y <= 0 || z > x);
        // require(y >= 0 || z < x);  // fixme: why errors??
    }
    function sub(uint x, int y) internal pure returns (uint z) {
        z = add(x, -y);
        require(y != -2**255);
    }
    function mul(uint x, int y) internal pure returns (int z) {
        z = int(x) * y;
        require(int(x) > 0);
        require(y >= 0 || int(x) != -2**255);
        require(y == 0 || z / y == int(x));
    }

    // --- Administration Engine ---
    function init(bytes32 ilk) public auth {
        require(ilks[ilk].rate == 0);
        ilks[ilk].rate = 10 ** 27;
    }

    // --- Fungibility Engine ---
    function move(bytes32 src, bytes32 dst, uint256 rad) public auth {
        require(int(rad) >= 0);
        dai[src] = sub(dai[src], int(rad));
        dai[dst] = add(dai[dst], int(rad));
        require(dai[src] >= 0 && dai[dst] >= 0);
    }
    function slip(bytes32 ilk, bytes32 guy, int256 wad) public auth {
        gem[ilk][guy] = add(gem[ilk][guy], wad);
        require(gem[ilk][guy] >= 0);
    }
    function flux(bytes32 ilk, bytes32 src, bytes32 dst, int256 wad) public auth {
        gem[ilk][src] = sub(gem[ilk][src], wad);
        gem[ilk][dst] = add(gem[ilk][dst], wad);
        require(gem[ilk][src] >= 0 && gem[ilk][dst] >= 0);
    }

    // --- CDP Engine ---
    function tune(bytes32 ilk, bytes32 u_, bytes32 v, bytes32 w, int dink, int dart) public auth {
        Urn storage u = urns[ilk][u_];
        Ilk storage i = ilks[ilk];

        u.ink = add(u.ink, dink);
        u.art = add(u.art, dart);
        i.Art = add(i.Art, dart);

        gem[ilk][v] = sub(gem[ilk][v], dink);
        dai[w]      = add(dai[w],      mul(i.rate, dart));
        debt        = add(debt,        mul(i.rate, dart));
    }

    // --- Liquidation Engine ---
    function grab(bytes32 ilk, bytes32 u_, bytes32 v, bytes32 w, int dink, int dart) public auth {
        Urn storage u = urns[ilk][u_];
        Ilk storage i = ilks[ilk];

        u.ink = add(u.ink, dink);
        u.art = add(u.art, dart);
        i.Art = add(i.Art, dart);

        gem[ilk][v] = sub(gem[ilk][v], dink);
        sin[w]      = sub(sin[w],      mul(i.rate, dart));
        vice        = sub(vice,        mul(i.rate, dart));
    }
    function heal(bytes32 u, bytes32 v, int rad) public auth {
        sin[u] = sub(sin[u], rad);
        dai[v] = sub(dai[v], rad);
        vice   = sub(vice,   rad);
        debt   = sub(debt,   rad);

        require(sin[u] >= 0 && dai[v] >= 0);
        require(vice   >= 0 && debt    >= 0);
    }

    // --- Stability Engine ---
    function fold(bytes32 ilk, bytes32 vow, int rate) public auth {
        Ilk storage i = ilks[ilk];
        i.rate   = add(i.rate, rate);
        int rad  = mul(i.Art, rate);
        dai[vow] = add(dai[vow], rad);
        debt     = add(debt, rad);
    }
}
