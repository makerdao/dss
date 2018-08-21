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
        int256  rate;  // ray
        int256  Art;   // wad
    }
    struct Urn {
        int256 gem;    // wad
        int256 ink;    // wad
        int256 art;    // wad
    }

    mapping (bytes32 => int256)                   public dai;  // rad
    mapping (bytes32 => int256)                   public sin;  // rad
    mapping (bytes32 => Ilk)                      public ilks;
    mapping (bytes32 => mapping (bytes32 => Urn)) public urns;

    function dai(address guy) public view returns (int) {
        return dai[bytes32(guy)];
    }
    function urns(bytes32 ilk, address lad) public view returns (int,int,int) {
        Urn storage u = urns[ilk][bytes32(lad)];
        return (u.gem, u.ink, u.art);
    }

    int256  public Tab;   // rad
    int256  public vice;  // rad

    function add(int x, int y) internal pure returns (int z) {
        z = x + y;
        require(y <= 0 || z > x);
        require(y >= 0 || z < x);
    }
    function sub(int x, int y) internal pure returns (int z) {
        require(y != -2**255);
        z = add(x, -y);
    }
    function mul(int x, int y) internal pure returns (int z) {
        z = x * y;
        require(y >= 0 || x != -2**255);
        require(y == 0 || z / y == x);
    }

    // --- Administration Engine ---
    function file(bytes32 ilk, bytes32 what, int risk) public auth {
        if (what == "rate") ilks[ilk].rate = risk;
    }

    // --- Fungibility Engine ---
    int256 constant ONE = 10 ** 27;
    function move(address src, address dst, uint wad) public auth {
        require(int(wad) >= 0);
        move(src, dst, int(wad));
    }
    function move(address src_, address dst_, int wad) public auth {
        bytes32 src = bytes32(src_);
        bytes32 dst = bytes32(dst_);
        int rad = mul(wad, ONE);
        dai[src] = sub(dai[src], rad);
        dai[dst] = add(dai[dst], rad);
        require(dai[src] >= 0 && dai[dst] >= 0);
    }
    function slip(bytes32 ilk, address guy_, int256 wad) public auth {
        bytes32 guy = bytes32(guy_);
        urns[ilk][guy].gem = add(urns[ilk][guy].gem, wad);
        require(urns[ilk][guy].gem >= 0);
    }
    function flux(bytes32 ilk, address src_, address dst_, int256 wad) public auth {
        bytes32 src = bytes32(src_);
        bytes32 dst = bytes32(dst_);
        urns[ilk][src].gem = sub(urns[ilk][src].gem, wad);
        urns[ilk][dst].gem = add(urns[ilk][dst].gem, wad);
        require(urns[ilk][src].gem >= 0 && urns[ilk][dst].gem >= 0);
    }

    // --- CDP Engine ---
    function tune(bytes32 ilk, address u_, address v_, address w_, int dink, int dart) public auth {
        Urn storage u = urns[ilk][bytes32(u_)];
        Urn storage v = urns[ilk][bytes32(v_)];
        Ilk storage i = ilks[ilk];

        v.gem = sub(v.gem, dink);
        u.ink = add(u.ink, dink);
        u.art = add(u.art, dart);
        i.Art = add(i.Art, dart);

        dai[bytes32(w_)] = add(dai[bytes32(w_)], mul(i.rate, dart));
        Tab     = add(Tab,     mul(i.rate, dart));
    }

    // --- Liquidation Engine ---
    function grab(bytes32 ilk, address u_, address v_, address w_, int dink, int dart) public auth {
        Urn storage u = urns[ilk][bytes32(u_)];
        Urn storage v = urns[ilk][bytes32(v_)];
        Ilk storage i = ilks[ilk];

        v.gem = sub(v.gem, dink);
        u.ink = add(u.ink, dink);
        u.art = add(u.art, dart);
        i.Art = add(i.Art, dart);

        sin[bytes32(w_)] = sub(sin[bytes32(w_)], mul(i.rate, dart));
        vice    = sub(vice,    mul(i.rate, dart));
    }
    function heal(address u_, address v_, int wad) public auth {
        bytes32 u = bytes32(u_);
        bytes32 v = bytes32(v_);
        int rad = mul(wad, ONE);

        sin[u] = sub(sin[u], rad);
        dai[v] = sub(dai[v], rad);
        vice   = sub(vice,   rad);
        Tab    = sub(Tab,    rad);

        require(sin[u] >= 0 && dai[v] >= 0);
        require(vice   >= 0 && Tab    >= 0);
    }

    // --- Stability Engine ---
    function fold(bytes32 ilk, address vow_, int rate) public auth {
        bytes32 vow = bytes32(vow_);
        Ilk storage i = ilks[ilk];
        i.rate   = add(i.rate, rate);
        int rad  = mul(i.Art, rate);
        dai[vow] = add(dai[vow], rad);
        Tab      = add(Tab, rad);
    }
}
