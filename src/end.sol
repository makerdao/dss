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
    function ilks(bytes32 ilk) public returns (Ilk memory);
    function urns(bytes32 ilk, address urn) public returns (Urn memory);
    function debt() public returns (uint);
    function move(address src, address dst, uint256 rad) public;
    function hope(address) public;
    function flux(bytes32 ilk, address src, address dst, uint256 rad) public;
    function grab(bytes32 i, address u, address v, address w, int256 dink, int256 dart) public;
    function suck(address u, address v, uint256 rad) public;
    function cage() public;
}
contract CatLike {
    struct Ilk {
        address flip;  // Liquidator
        uint256 chop;  // Liquidation Penalty   [ray]
        uint256 lump;  // Liquidation Quantity  [rad]
    }
    function ilks(bytes32) public returns (Ilk memory);
    function cage() public;
}
contract VowLike {
    function Joy() public view returns (uint);
    function heal(uint256 rad) public;
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
    function live() public view returns (uint);
    function bids(uint id) public view returns (Bid memory);
    function yank(uint id) public;
}

contract PipLike {
    function read() public view returns (bytes32);
}

contract Spotty {
    struct Ilk {
        PipLike pip;
        uint256 mat;
    }
    function ilks(bytes32) public view returns (Ilk memory);
}

/*
    This is the `End`, it coordinates Global Settlement. This is an
    involved, stateful process that takes place over several steps:

    First we freeze the system and lock the prices for each ilk:

    1. `cage()`:
        - freezes user entrypoints
        - cancels flop/flap auctions
        - starts cooldown period

    2. `cage(ilk)`:
       - set the cage price for each `ilk`, reading off the price feed
       - lock the flip auction manager for each `ilk`

    Process outstanding CDPs and auctions:

    3. Process auctions
       `skip(ilk, id)`:
       - cancel individual flip auctions in the `tend` (forward) phase
       - `dent` (reverse) phase auctions can continue with no issue

    4. Process CDPs
       `skim(ilk, urn)`:
       - cancels debt
       - any excess collateral remains
       - backing collateral taken

    Collateral may now be retrieved from processed CDPs:

    5. `free(ilk)`:
        - remove collateral from the caller's CDP
        - owner can call as needed

    After the processing period has elapsed, we enable calculation of
    the final price for each collateral type:

    6. `thaw()`:
       - only callable after processing time period elapsed
       - assumption that all under-collateralised CDPs are processed
       - may also need to have processed extra CDPs to cover surplus in the vow

    7. `flow(ilk)`:
        - calculate the `fix` cash price for a given ilk
        - adjusts the cage price in the case of deficit/surplus

    At this point we have computed the final price for each collateral
    type and users can now turn their dai into collateral. Each unit dai
    can claim a fixed portfolio of collateral.

    8. `shop(wad)`:
        - lock some dai in preparation for `cash`

    9. `cash(ilk, wad)`
        - exchange some dai for gems from a specific ilk
*/

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

    Spotty   public spot;

    uint256  public live;
    uint256  public wait;
    uint256  public when;
    uint256  public debt;

    mapping (address => uint256)                      public dai;
    mapping (bytes32 => uint256)                      public tag;
    mapping (bytes32 => uint256)                      public gap;
    mapping (bytes32 => uint256)                      public fix;
    mapping (bytes32 => uint256)                      public art;
    mapping (bytes32 => mapping (address => uint256)) public bags;

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
        live = 1;
    }

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    uint constant RAY = 10 ** 27;
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, y) / RAY;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, RAY) / y;
    }

    // --- Administration ---
    function file(bytes32 what, address data) public auth {
        if (what == "vat")  vat = VatLike(data);
        if (what == "cat")  cat = CatLike(data);
        if (what == "vow")  vow = VowLike(data);
        if (what == "spot") spot = Spotty(data);
    }
    function file(bytes32 what, uint256 data) public auth {
        if (what == "wait") wait = data;
    }

    // --- Settlement ---
    function cage() public auth {
        require(live == 1);
        live = 0;
        when = now;
        vat.cage();
        cat.cage();
        vow.cage();
    }

    function cage(bytes32 ilk) public {
        require(live == 0);
        require(tag[ilk] == 0);
        tag[ilk] = rdiv(RAY, uint(spot.ilks(ilk).pip.read()));
    }

    function skip(bytes32 ilk, uint256 id) public {
        require(live == 0);

        Flippy flip = Flippy(cat.ilks(ilk).flip);
        if (flip.live() == 1) flip.cage();

        VatLike.Ilk memory i = vat.ilks(ilk);
        Flippy.Bid  memory bid = Flippy(flip).bids(id);

        vat.suck(address(vow), address(vow),  bid.tab);
        vat.suck(address(vow), address(this), bid.bid);
        vat.hope(address(flip));
        flip.yank(id);

        vat.grab(ilk, bid.urn, address(this), address(vow), int(bid.lot), int(bid.tab / i.rate));
    }

    function skim(bytes32 ilk, address urn) public {
        require(tag[ilk] != 0);
        VatLike.Ilk memory i = vat.ilks(ilk);
        VatLike.Urn memory u = vat.urns(ilk, urn);

        uint owe = rmul(rmul(u.art, i.rate), tag[ilk]);
        uint wad = min(u.ink, owe);
        gap[ilk] = add(gap[ilk], sub(owe, wad));
        art[ilk] = add(art[ilk], u.art);

        require(int(wad) > 0);
        vat.grab(ilk, urn, address(this), address(vow), -int(wad), -int(u.art));
    }

    function free(bytes32 ilk) public {
        VatLike.Urn memory u = vat.urns(ilk, msg.sender);
        require(u.art == 0);
        require(int(u.ink) > 0);
        vat.grab(ilk, msg.sender, msg.sender, address(vow), -int(u.ink), 0);
    }

    function thaw() public {
        require(now >= when + wait);
        require(debt == 0);
        require(vow.Joy() == 0);
        debt = vat.debt();
    }
    function flow(bytes32 ilk) public {
        require(debt != 0);
        require(fix[ilk] == 0);

        VatLike.Ilk memory i = vat.ilks(ilk);
        uint256 wad = rmul(rmul(add(i.Art, art[ilk]), i.rate), tag[ilk]);
        fix[ilk] = rdiv(mul(sub(wad, gap[ilk]), RAY), debt);
    }

    function shop(uint256 wad) public {
        require(debt != 0);
        vat.move(msg.sender, address(vow), mul(wad, RAY));
        vow.heal(mul(wad, RAY));
        dai[msg.sender] = add(dai[msg.sender], wad);
    }
    function cash(bytes32 ilk, uint wad) public {
        require(fix[ilk] != 0);
        vat.flux(ilk, address(this), msg.sender, rmul(wad, fix[ilk]));
        bags[ilk][msg.sender] = add(bags[ilk][msg.sender], wad);
        require(bags[ilk][msg.sender] <= dai[msg.sender]);
    }
}
