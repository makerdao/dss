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
    function rely(address guy) public note auth { wards[guy] = 1; }
    function deny(address guy) public note auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- Data ---
    struct Ilk {
        uint256 Art;   // Total Normalised Debt     [wad]
        uint256 rate;  // Accumulated Rates         [ray]
        uint256 spot;  // Price with Safety Margin  [ray]
        uint256 line;  // Debt Ceiling              [rad]
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
        bytes4   indexed  sig,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        bytes32  indexed  too,
        bytes             fax
    ) anonymous;
    modifier note {
        bytes32 foo;
        bytes32 bar;
        bytes32 too;
        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            too := calldataload(68)
        }
        emit Note(msg.sig, foo, bar, too, msg.data); _;
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
    }

    // --- Fungibility ---
    function slip(bytes32 ilk, bytes32 guy, int256 rad) public note auth {
        gem[ilk][guy] = add(gem[ilk][guy], rad);
    }
    function flux(bytes32 ilk, bytes32 src, bytes32 dst, int256 rad) public note auth {
        gem[ilk][src] = sub(gem[ilk][src], rad);
        gem[ilk][dst] = add(gem[ilk][dst], rad);
    }
    function move(bytes32 src, bytes32 dst, int256 rad) public note auth {
        dai[src] = sub(dai[src], rad);
        dai[dst] = add(dai[dst], rad);
    }

    // --- CDP ---
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
        bool safe = mul(urn.ink, ilk.spot) >= mul(urn.art, ilk.rate);

        require((calm || cool) && (nice || safe));

        require(msg.sender == address(bytes20(u)) ||  nice);
        require(msg.sender == address(bytes20(v)) || !firm);
        require(msg.sender == address(bytes20(w)) || !cool);

        require(live == 1);
        require(ilk.rate != 0);
    }
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
