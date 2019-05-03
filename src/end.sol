/// end.sol -- global settlement engine

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
// Copyright (C) 2018 Lev Livnev <lev@liv.nev.org.uk>
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

contract VatLike {
    struct Ilk {
        uint256 Art;
        uint256 rate;
        uint256 spot;
        uint256 line;
        uint256 dust;
    }
    struct Urn {
        uint256 ink;
        uint256 art;
    }
    function sin(address) public view returns (uint);
    function dai(address) public view returns (uint);
    function ilks(bytes32 ilk) public returns (Ilk memory);
    function urns(bytes32 ilk, address urn) public returns (Urn memory);
    function move(address src, address dst, uint256 rad) public;
    function flux(bytes32 ilk, address src, address dst, uint256 rad) public;
    function tune(bytes32 i, address u, address v, address w, int256 dink, int256 dart) public;
    function grab(bytes32 i, address u, address v, address w, int256 dink, int256 dart) public;
    function heal(uint256 rad) public;
    function suck(address u, address v, uint256 rad) public;
    function cage() public;
}
contract CatLike {
    struct Ilk {
        address flip;  // Liquidator
        uint256 chop;  // Liquidation Penalty   [ray]
        uint256 lump;  // Liquidation Quantity  [wad]
    }
    function ilks(bytes32) public returns (Ilk memory);
    function cage() public;
}
contract VowLike {
    function Joy() public view returns (uint);
    function Woe() public view returns (uint);
    function Ash() public view returns (uint);
    function heal(uint256 rad) public;
    function kiss(uint256 rad) public;
    function cage() public;
}
contract Flippy {
    struct Bid {
        uint256 bid;
        uint256 lot;
        address guy;
        uint48  tic;
        uint48  end;
        address urn;
        address gal;
        uint256 tab;
    }
    function cage() public;
    function bids(uint id) public view returns (Bid memory);
    function yank(uint id) public;
}

contract End {

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) public auth { wards[guy] = 1; }
    function deny(address guy) public auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- Data ---
    VatLike  public vat;
    CatLike  public cat;
    VowLike  public vow;
    uint256  public live;

    mapping (address => uint256)                      public dai;
    mapping (bytes32 => uint256)                      public tags;
    mapping (bytes32 => uint256)                      public fixs;
    mapping (bytes32 => mapping (address => uint256)) public bags;

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
        live = 1;
    }

    // --- Helpers ---
    // function b32(address a) internal pure returns (bytes32 b) {
    //     b = bytes32(bytes20(a));
    // }

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
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
    function u2i(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0);
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        if (x > y) { z = y; } else { z = x; }
    }
    function min(int x, int y) internal pure returns (int z) {
        if (x > y) { z = y; } else { z = x; }
    }

    // --- Administration ---
    function file(bytes32 what, address data) public auth {
        if (what == "vat") vat = VatLike(data);
        if (what == "cat") cat = CatLike(data);
        if (what == "vow") vow = VowLike(data);
    }

    // --- Settlement ---
    function cage() public auth {
        require(live == 1);
        live = 0;
        vat.cage();
        cat.cage();
        vow.cage();
    }

    function cage(bytes32 ilk, uint256 tag, uint256 fix) public auth {
        require(live == 0);
        tags[ilk] = tag;
        fixs[ilk] = fix;
        Flippy(cat.ilks(ilk).flip).cage();
    }

    function skip(bytes32 ilk, uint256 id) public {
        require(live == 0);

        address flip = cat.ilks(ilk).flip;
        VatLike.Ilk memory i   = vat.ilks(ilk);
        Flippy.Bid  memory bid = Flippy(flip).bids(id);

        Flippy(flip).yank(id);
        vat.suck(address(vow), address(vow), bid.tab);
        vat.grab(ilk, bid.urn, address(this), address(vow), int(bid.lot), int(bid.tab / i.rate));
    }

    function skim(bytes32 ilk, address urn) public {
        require(tags[ilk] != 0);

        VatLike.Ilk memory i = vat.ilks(ilk);
        VatLike.Urn memory u = vat.urns(ilk, urn);

        uint war = min(u.ink, rmul(rmul(u.art, i.rate), tags[ilk]));

        vat.grab(ilk, urn, address(this), address(this), -int(war), -int(u.art));
    }

    function free(bytes32 ilk) public {
        VatLike.Urn memory u = vat.urns(ilk, msg.sender);
        require(u.art == 0);
        vat.grab(ilk, msg.sender, msg.sender, msg.sender, -int(u.ink), 0);
    }

    function shop(uint256 wad) public {
        vat.move(msg.sender, address(this), mul(wad, RAY));
        vat.heal(mul(wad, RAY));
        dai[msg.sender] = add(dai[msg.sender], wad);
    }

    function pack(bytes32 ilk) public {
        require(bags[ilk][msg.sender] == 0);
        bags[ilk][msg.sender] = add(bags[ilk][msg.sender], dai[msg.sender]);
    }

    function cash(bytes32 ilk) public {
        vat.flux(ilk, address(this), msg.sender, rmul(bags[ilk][msg.sender], fixs[ilk]));
        bags[ilk][msg.sender]  = 0;
        dai[msg.sender]        = 0;
    }

    function vent(uint256 rad) public {
        vat.heal(rad);
    }
}
