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

pragma solidity ^0.5.12;

import "./lib.sol";

contract Kicker {
    function kick(address urn, address gal, uint tab, uint lot, uint bid)
        public returns (uint);
}

contract VatLike {
    function ilks(bytes32) external view returns (
        uint256 Art,   // [wad]
        uint256 rate,  // [ray]
        uint256 spot   // [ray]
    );
    function urns(bytes32,address) external view returns (
        uint256 ink,   // [wad]
        uint256 art    // [wad]
    );
    function grab(bytes32,address,address,address,int,int) external;
    function hope(address) external;
    function nope(address) external;
}

contract VowLike {
    function fess(uint) external;
}

contract Cat is LibNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Cat/not-authorized");
        _;
    }

    // --- Data ---
    struct Ilk {
        address flip;  // Liquidator
        uint256 chop;  // Liquidation Penalty   [ray]
        uint256 lump;  // Liquidation Quantity  [wad]
    }

    mapping (bytes32 => Ilk) public ilks;

    uint256 public live;  // Active Flag
    VatLike public vat;   // CDP Engine
    VowLike public vow;   // Debt Engine

    // --- Events ---
    event Bite(
      bytes32 indexed ilk,
      address indexed urn,
      uint256 ink,
      uint256 art,
      uint256 tab,
      address flip,
      uint256 id
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
        require(y == 0 || (z = x * y) / y == x);
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, y) / ONE;
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        if (x > y) { z = y; } else { z = x; }
    }

    // --- Administration ---
    function file(bytes32 what, address data) external note auth {
        if (what == "vow") vow = VowLike(data);
        else revert("Cat/file-unrecognized-param");
    }
    function file(bytes32 ilk, bytes32 what, uint data) external note auth {
        if (what == "chop") ilks[ilk].chop = data;
        else if (what == "lump") ilks[ilk].lump = data;
        else revert("Cat/file-unrecognized-param");
    }
    function file(bytes32 ilk, bytes32 what, address flip) external note auth {
        if (what == "flip") {
            vat.nope(ilks[ilk].flip);
            ilks[ilk].flip = flip;
            vat.hope(flip);
        }
        else revert("Cat/file-unrecognized-param");
    }

    // --- CDP Liquidation ---
    function bite(bytes32 ilk, address urn) external returns (uint id) {
        (, uint rate, uint spot) = vat.ilks(ilk);
        (uint ink, uint art) = vat.urns(ilk, urn);

        require(live == 1, "Cat/not-live");
        require(spot > 0 && mul(ink, spot) < mul(art, rate), "Cat/not-unsafe");

        uint lot = min(ink, ilks[ilk].lump);
        art      = min(art, mul(lot, art) / ink);

        require(lot <= 2**255 && art <= 2**255, "Cat/overflow");
        vat.grab(ilk, urn, address(this), address(vow), -int(lot), -int(art));

        vow.fess(mul(art, rate));
        id = Kicker(ilks[ilk].flip).kick({ urn: urn
                                         , gal: address(vow)
                                         , tab: rmul(mul(art, rate), ilks[ilk].chop)
                                         , lot: lot
                                         , bid: 0
                                         });

        emit Bite(ilk, urn, lot, art, mul(art, rate), ilks[ilk].flip, id);
    }

    function cage() external note auth {
        live = 0;
    }
}
