/// vat.sol -- Dai CDP database

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

contract Vat {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) public note auth { wards[usr] = 1; }
    function deny(address usr) public note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    mapping(address => mapping (address => uint)) public can;
    function hope(address usr) public { can[msg.sender][usr] = 1; }
    function nope(address usr) public { can[msg.sender][usr] = 0; }
    function wish(bytes32 bit, address usr) internal view returns (bool) {
        return address(bytes20(bit)) == usr || can[address(bytes20(bit))][usr] == 1;
    }

    // --- Data ---
    struct Ilk {
        uint256 Art;   // Total Normalised Debt     [wad]
        uint256 rate;  // Accumulated Rates         [ray]
        uint256 spot;  // Price with Safety Margin  [ray]
        uint256 line;  // Debt Ceiling              [rad]
        uint256 dust;  // Urn Debt Floor            [rad]
    }
    struct Urn {
        uint256 ink;   // Locked Collateral  [wad]
        uint256 art;   // Normalised Debt    [wad]
    }

    mapping (bytes32 => Ilk)                       public ilks;
    mapping (bytes32 => mapping (bytes32 => Urn )) public urns;
    mapping (bytes32 => mapping (bytes32 => uint)) public gem;  // [wad]
    mapping (bytes32 => uint256)                   public dai;  // [rad]
    mapping (bytes32 => uint256)                   public sin;  // [rad]

    uint256 public debt;  // Total Dai Issued    [rad]
    uint256 public vice;  // Total Unbacked Dai  [rad]
    uint256 public Line;  // Total Debt Ceiling  [wad]
    uint256 public live;  // Access Flag

    // --- Logs ---
    event Note(
        bytes4   indexed  hash,
        bytes32  indexed  arg1,
        bytes32  indexed  arg2,
        bytes32  indexed  arg3,
        bytes             data
    ) anonymous;
    modifier note {
        bytes32 arg1;
        bytes32 arg2;
        bytes32 arg3;
        assembly {
            arg1 := calldataload(4)
            arg2 := calldataload(36)
            arg3 := calldataload(68)
        }
        emit Note(msg.sig, arg1, arg2, arg3, msg.data); _;
    }

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
        live = 1;
    }

    // --- Math ---
    function add(uint x, int y) internal pure returns (uint z) {
      assembly {
        z := add(x, y)
        if sgt(y, 0) { if iszero(gt(z, x)) { revert(0, 0) } }
        if slt(y, 0) { if iszero(lt(z, x)) { revert(0, 0) } }
      }
    }
    function sub(uint x, int y) internal pure returns (uint z) {
      assembly {
        z := sub(x, y)
        if slt(y, 0) { if iszero(gt(z, x)) { revert(0, 0) } }
        if sgt(y, 0) { if iszero(lt(z, x)) { revert(0, 0) } }
      }
    }
    function mul(uint x, int y) internal pure returns (int z) {
      assembly {
        z := mul(x, y)
        if slt(x, 0) { revert(0, 0) }
        if iszero(eq(y, 0)) { if iszero(eq(sdiv(z, y), x)) { revert(0, 0) } }
      }
    }
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    function init(bytes32 ilk) public note auth {
        require(ilks[ilk].rate == 0);
        ilks[ilk].rate = 10 ** 27;
    }
    function file(bytes32 what, uint data) public note auth {
        if (what == "Line") Line = data;
    }
    function file(bytes32 ilk, bytes32 what, uint data) public note auth {
        if (what == "spot") ilks[ilk].spot = data;
        if (what == "line") ilks[ilk].line = data;
        if (what == "dust") ilks[ilk].dust = data;
    }

    // --- Fungibility ---
    function slip(bytes32 ilk, bytes32 usr, int256 wad) public note auth {
        gem[ilk][usr] = add(gem[ilk][usr], wad);
    }
    function flux(bytes32 ilk, bytes32 src, bytes32 dst, uint256 wad) public note {
        require(wish(src, msg.sender));
        gem[ilk][src] = sub(gem[ilk][src], wad);
        gem[ilk][dst] = add(gem[ilk][dst], wad);
    }
    function move(bytes32 src, bytes32 dst, uint256 rad) public note {
        require(wish(src, msg.sender));
        dai[src] = sub(dai[src], rad);
        dai[dst] = add(dai[dst], rad);
    }

    // --- CDP Manipulation ---
    function frob(bytes32 i, bytes32 u, bytes32 v, bytes32 w, int dink, int dart) public note {
        Urn storage urn = urns[i][u];
        Ilk storage ilk = ilks[i];

        urn.ink = add(urn.ink, dink);
        urn.art = add(urn.art, dart);
        ilk.Art = add(ilk.Art, dart);

        gem[i][v] = sub(gem[i][v], dink);
        dai[w]    = add(dai[w], mul(ilk.rate, dart));
        debt      = add(debt,   mul(ilk.rate, dart));

        bool cool = dart <= 0;
        bool firm = dink >= 0;
        bool nice = cool && firm;
        bool calm = mul(ilk.Art, ilk.rate) <= ilk.line && debt <= Line;
        bool safe = mul(urn.art, ilk.rate) <= mul(urn.ink, ilk.spot);

        require((calm || cool) && (nice || safe));

        require(wish(u, msg.sender) ||  nice);
        require(wish(v, msg.sender) || !firm);
        require(wish(w, msg.sender) || !cool);

        require(mul(urn.art, ilk.rate) >= ilk.dust || urn.art == 0);
        require(ilk.rate != 0);
        require(live == 1);
    }
    // --- CDP Fungibility ---
    function fork(bytes32 ilk, bytes32 src, bytes32 dst, int dink, int dart) public note {
        Urn storage u = urns[ilk][src];
        Urn storage v = urns[ilk][dst];
        Ilk storage i = ilks[ilk];

        u.ink = sub(u.ink, dink);
        u.art = sub(u.art, dart);
        v.ink = add(v.ink, dink);
        v.art = add(v.art, dart);

        // both sides consent
        require(wish(src, msg.sender) && wish(dst, msg.sender));

        // both sides safe
        require(mul(u.art, i.rate) <= mul(u.ink, i.spot));
        require(mul(v.art, i.rate) <= mul(v.ink, i.spot));

        // both sides non-dusty
        require(mul(u.art, i.rate) >= i.dust || u.art == 0);
        require(mul(v.art, i.rate) >= i.dust || v.art == 0);
    }
    // --- CDP Confiscation ---
    function grab(bytes32 i, bytes32 u, bytes32 v, bytes32 w, int dink, int dart) public note auth {
        Urn storage urn = urns[i][u];
        Ilk storage ilk = ilks[i];

        urn.ink = add(urn.ink, dink);
        urn.art = add(urn.art, dart);
        ilk.Art = add(ilk.Art, dart);

        gem[i][v] = sub(gem[i][v], dink);
        sin[w]    = sub(sin[w], mul(ilk.rate, dart));
        vice      = sub(vice,   mul(ilk.rate, dart));
    }

    // --- Settlement ---
    function heal(bytes32 u, bytes32 v, int rad) public note auth {
        sin[u] = sub(sin[u], rad);
        dai[v] = sub(dai[v], rad);
        vice   = sub(vice,   rad);
        debt   = sub(debt,   rad);
    }

    // --- Rates ---
    function fold(bytes32 i, bytes32 u, int rate) public note auth {
        Ilk storage ilk = ilks[i];
        ilk.rate = add(ilk.rate, rate);
        int rad  = mul(ilk.Art, rate);
        dai[u]   = add(dai[u], rad);
        debt     = add(debt,   rad);
    }
}
