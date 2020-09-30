/// dog.sol -- Dai liquidation module 2.0

// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
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

pragma solidity >=0.5.12;

// import "./lib.sol";

interface ClipperLike {
    function kick(uint256 tab, uint256 lot, address usr) external returns (uint256);
}

interface VatLike {
    function ilks(bytes32) external view returns (
        uint256 Art,  // [wad]
        uint256 rate, // [ray]
        uint256 spot, // [ray]
        uint256 line, // [rad]
        uint256 dust  // [rad]
    );
    function urns(bytes32,address) external view returns (
        uint256 ink,  // [wad]
        uint256 art   // [wad]
    );
    function grab(bytes32,address,address,address,int256,int256) external;
    function hope(address) external;
    function nope(address) external;
}

interface VowLike {
    function fess(uint256) external;
}
// TODO: should we remove LibNote and replace with custom events
contract Dog /* is LibNote */ {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) public /* note */ auth { wards[usr] = 1; }
    function deny(address usr) public /* note */ auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Dog/not-authorized");
        _;
    }

    // --- Data ---
    struct Ilk {
        address clip;  // Liquidator
        uint256 chop;  // Liquidation Penalty  [wad]
        uint256 hole;  // Max DAI needed to cover debt+fees of active auctions per ilk [rad]
        uint256 dirt;  // Amt DAI needed to cover debt+fees of active auctions per ilk [rad]
    }

    mapping (bytes32 => Ilk) public ilks;

    uint256 public live;  // Active Flag
    VatLike public vat;   // CDP Engine
    VowLike public vow;   // Debt Engine
    uint256 public Hole;  // Max DAI needed to cover debt+fees of active auctions [rad]
    uint256 public Dirt;  // Amt DAI needed to cover debt+fees of active auctions [rad]

    // --- Events ---
    event Bark(
      bytes32 indexed ilk,
      address indexed urn,
      uint256 ink,
      uint256 art,
      uint256 tab,
      address clip,
      uint256 id
    );

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        live = 1;
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x > y) { z = y; } else { z = x; }
    }
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    function file(bytes32 what, address data) external /* note */ auth {
        if (what == "vow") vow = VowLike(data);
        else revert("Dog/file-unrecognized-param");
    }
    function file(bytes32 what, uint256 data) external /* note */ auth {
        if (what == "Hole") Hole = data;
        else revert("Dog/file-unrecognized-param");
    }
    function file(bytes32 ilk, bytes32 what, uint256 data) external /* note */ auth {
        if (what == "chop") ilks[ilk].chop = data;
        else if (what == "hole") ilks[ilk].hole = data;
        else revert("Dog/file-unrecognized-param");
    }
    function file(bytes32 ilk, bytes32 what, address clip) external /* note */ auth {
        if (what == "clip") ilks[ilk].clip = clip;
        else revert("Dog/file-unrecognized-param");
    }

    // --- CDP Liquidation: all bark and no bite ---
    function bark(bytes32 ilk, address urn) external returns (uint256 id) {
        require(live == 1, "Dog/not-live");

        (uint256 ink, uint256 art) = vat.urns(ilk, urn);
        Ilk memory milk = ilks[ilk];
        uint256 dart;
        uint256 rate;
        uint256 dust;
        {
            uint256 spot;
            (,rate, spot,, dust) = vat.ilks(ilk);
            require(spot > 0 && mul(ink, spot) < mul(art, rate), "Dog/not-unsafe");

            uint256 room = min(sub(Hole, Dirt), sub(milk.hole, milk.dirt));

            // Test whether the remaining space in the Hole is dusty
            require(room > 0 && room >= dust, "Dog/liquidation-limit-hit");

            dart = min(art, mul(room, WAD) / rate / milk.chop);
        }

        uint256 dink = min(ink, mul(ink, dart) / art);

        require(dink > 0, "Dog/null-auction");
        require(dart <= 2**255 && dink <= 2**255, "Dog/overflow");

        // This may leave the CDP in a dusty state
        vat.grab(
            ilk, urn, milk.clip, address(vow), -int256(dink), -int256(dart)
        );
        
        uint256 due = mul(dart, rate);
        vow.fess(due);

        {   // Avoid stack too deep
            // This calcuation will overflow if dart*rate exceeds ~10^14
            uint256 tab = mul(due, milk.chop) / WAD;
            Dirt = add(Dirt, tab);
            ilks[ilk].dirt = add(milk.dirt, tab);

            id = ClipperLike(milk.clip).kick({
                tab: tab,
                lot: dink,
                usr: urn
            });
        }

        emit Bark(ilk, urn, dink, dart, due, milk.clip, id);
    }

    function digs(bytes32 ilk, uint256 rad) external /* note */ auth {
        Dirt = sub(Dirt, rad);
        ilks[ilk].dirt = sub(ilks[ilk].dirt, rad);
    }

    function cage() external /* note */ auth {
        live = 0;
    }
}
