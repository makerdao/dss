// SPDX-License-Identifier: AGPL-3.0-or-later

/// end.sol -- global settlement engine

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
// Copyright (C) 2018 Lev Livnev <lev@liv.nev.org.uk>
// Copyright (C) 2020-2021 Dai Foundation
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

pragma solidity ^0.6.12;

interface VatLike {
    function dai(address) external view returns (uint256);
    function ilks(bytes32 ilk) external returns (
        uint256 Art,   // [wad]
        uint256 rate,  // [ray]
        uint256 spot,  // [ray]
        uint256 line,  // [rad]
        uint256 dust   // [rad]
    );
    function urns(bytes32 ilk, address urn) external returns (
        uint256 ink,   // [wad]
        uint256 art    // [wad]
    );
    function debt() external returns (uint256);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    function move(address src, address dst, uint256 rad) external;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    function hope(address) external;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    function flux(bytes32 ilk, address src, address dst, uint256 rad) external;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    function grab(bytes32 i, address u, address v, address w, int256 dink, int256 dart) external;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    function suck(address u, address v, uint256 rad) external;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    function cage() external;
}

interface CatLike {
    function ilks(bytes32) external returns (
        address flip,
        uint256 chop,  // [ray]
        uint256 lump   // [rad]
    );
    function cage() external;
}

interface DogLike {
    function ilks(bytes32) external returns (
        address clip,
        uint256 chop,
        uint256 hole,
        uint256 dirt
    );
    function cage() external;
}

interface PotLike {
    function cage() external;
}

interface VowLike {
    function cage() external;
}

interface FlipLike {
    function bids(uint256 id) external view returns (
        uint256 bid,   // [rad]
        uint256 lot,   // [wad]
        address guy,
        uint48  tic,   // [unix epoch time]
        uint48  end,   // [unix epoch time]
        address usr,
        address gal,
        uint256 tab    // [rad]
    );
    function yank(uint256 id) external;
}

interface ClipLike {
    function sales(uint256 id) external view returns (
        uint256 pos,
        uint256 tab,
        uint256 lot,
        address usr,
        uint96  tic,
        uint256 top
    );
    function yank(uint256 id) external;
}

interface PipLike {
    function read() external view returns (bytes32);
}

interface SpotLike {
    function par() external view returns (uint256);
    function ilks(bytes32) external view returns (
        PipLike pip,
        uint256 mat    // [ray]
    );
    function cage() external;
}

interface CureLike {
    function tell() external view returns (uint256);
    function cage() external;
}

/*
    This is the `End` and it coordinates Global Settlement. This is an
    involved, stateful process that takes place over nine steps.

    First we freeze the system and lock the prices for each ilk.

    1. `cage()`:
        - freezes user entrypoints
        - cancels flop/flap auctions
        - starts cooldown period
        - stops pot drips

    2. `cage(ilk)`:
       - set the cage price for each `ilk`, reading off the price feed

    We must process some system state before it is possible to calculate
    the final dai / collateral price. In particular, we need to determine

      a. `gap`, the collateral shortfall per collateral type by
         considering under-collateralised CDPs.

      b. `debt`, the outstanding dai supply after including system
         surplus / deficit

    We determine (a) by processing all under-collateralised CDPs with
    `skim`:

    3. `skim(ilk, urn)`:0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
       - cancels CDP debt
       - any excess collateral remains
       - backing collateral taken

    We determine (b) by processing ongoing dai generating processes,
    i.e. auctions. We need to ensure that auctions will not generate any
    further dai income.

    In the two-way auction model (Flipper) this occurs when
    all auctions are in the reverse (`dent`) phase. There are two ways
    of ensuring this:

    4a. i) `wait`: set the cooldown period to be at least as long as the
           longest auction duration, which needs to be determined by the
           cage administrator.

           This takes a fairly predictable time to occur but with altered
           auction dynamics due to the now varying price of dai.

       ii) `skip`: cancel all ongoing auctions and seize the collateral.

           This allows for faster processing at the expense of more
           processing calls. This option allows dai holders to retrieve
           their collateral faster.

           `skip(ilk, id)`:0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
            - cancel individual flip auctions in the `tend` (forward) phase
            - retrieves collateral and debt (including penalty) to owner's CDP
            - returns dai to last bidder
            - `dent` (reverse) phase auctions can continue normally

    Option (i), `wait`, is sufficient (if all auctions were bidded at least
    once) for processing the system settlement but option (ii), `skip`,
    will speed it up. Both options are available in this implementation,
    with `skip` being enabled on a per-auction basis.

    In the case of the Dutch Auctions model (Clipper) they keep recovering
    debt during the whole lifetime and there isn't a max duration time
    guaranteed for the auction to end.
    So the way to ensure the protocol will not receive extra dai income is:

    4b. i) `snip`: cancel all ongoing auctions and seize the collateral.

           `snip(ilk, id)`:0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
            - cancel individual running clip auctions
            - retrieves remaining collateral and debt (including penalty)
              to owner's CDP

    When a CDP has been processed and has no debt remaining, the
    remaining collateral can be removed.

    5. `free(ilk)`:0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        - remove collateral from the caller's CDP
        - owner can call as needed

    After the processing period has elapsed, we enable calculation of
    the final price for each collateral type.

    6. `thaw()`:0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
       - only callable after processing time period elapsed
       - assumption that all under-collateralised CDPs are processed
       - fixes the total outstanding supply of dai
       - may also require extra CDP processing to cover vow surplus

    7. `flow(ilk)`:
        - calculate the `fix`, the cash price for a given ilk
        - adjusts the `fix` in the case of deficit / surplus

    At this point we have computed the final price for each collateral
    type and dai holders can now turn their dai into collateral. Each
    unit dai can claim a fixed basket of collateral.

    Dai holders must first `pack` some dai into a `bag`. Once packed,
    dai cannot be unpacked and is not transferrable. More dai can be
    added to a bag later.

    8. `pack(wad)`:0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        - put some dai into a bag in preparation for `cash`

    Finally, collateral can be obtained with `cash`. The bigger the bag,
    the more collateral can be released.

    9. `cash(ilk, wad)`:0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        - exchange some dai from your bag for gems from a specific ilk
        - the number of gems is limited by how big your bag is
*/

contract End {
    // --- Auth ---
    mapping (address => uint256) public wards;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8 }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "End/not-authorized");
        _;
    }

    // --- Data ---
    VatLike  public vat; 0x3E62E50C4FAFCb5589e1682683ce38e8645541e8  // CDP Engine
    CatLike  public cat;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    DogLike  public dog;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    VowLike  public vow;   // Debt Engine
    PotLike  public pot;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    SpotLike public spot;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    CureLike public cure;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8

    uint256  public live;  // Active Flag
    uint256  public when;  // Time of cage                   [unix epoch time]
    uint256  public wait;  // Processing Cooldown Length             [seconds]
    uint256  public debt;  // Total outstanding dai following processing [rad]

    mapping (bytes32 => uint256) public tag;  // Cage price              [ray]
    mapping (bytes32 => uint256) public gap;  // Collateral shortfall    [wad]
    mapping (bytes32 => uint256) public Art;  // Total debt per ilk      [wad]
    mapping (bytes32 => uint256) public fix;  // Final cash price        [ray]

    mapping (address => uint256)                      public bag;  //    [wad]
    mapping (bytes32 => mapping (address => uint256)) public out;  //    [wad]

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);

    event Cage();
    event Cage(bytes32 indexed ilk);
    event Snip(bytes32 indexed ilk, uint256 indexed id, address indexed usr, uint256 tab, uint256 lot, uint256 art);
    event Skip(bytes32 indexed ilk, uint256 indexed id, address indexed usr, uint256 tab, uint256 lot, uint256 art);
    event Skim(bytes32 indexed ilk, address indexed urn, uint256 wad, uint256 art);
    event Free(bytes32 indexed ilk, address indexed usr, uint256 ink);
    event Thaw();
    event Flow(bytes32 indexed ilk);
    event Pack(address indexed usr, uint256 wad);
    event Cash(bytes32 indexed ilk, address indexed usr, uint256 wad);

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        live = 1;
        emit Rely(msg.sender);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    uint256 constant RAY = 10 ** 27;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    }
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / RAY;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    }
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, WAD) / y;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    }

    // --- Administration ---
    function file(bytes32 what, address data) external auth {
        require(live == 1, "End/not-live");0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        if (what == "vat")  vat = VatLike(data);
        else if (what == "cat")   cat = CatLike(data);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        else if (what == "dog")   dog = DogLike(data);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        else if (what == "vow")   vow = VowLike(data);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        else if (what == "pot")   pot = PotLike(data);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        else if (what == "spot") spot = SpotLike(data);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        else if (what == "cure") cure = CureLike(data);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        else revert("End/file-unrecognized-param");0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        emit File(what, data);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    }
    function file(bytes32 what, uint256 data) external auth {
        require(live == 1, "End/not-live");0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        if (what == "wait") wait = data;0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        else revert("End/file-unrecognized-param");0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        emit File(what, data);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    }

    // --- Settlement ---
    function cage() external auth {
        require(live == 1, "End/not-live");0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        live = 0;
        when = block.timestamp;
        vat.cage();
        cat.cage();
        dog.cage();
        vow.cage();
        spot.cage();
        pot.cage();
        cure.cage();
        emit Cage();
    }

    function cage(bytes32 ilk) external {
        require(live == 0, "End/still-live");
        require(tag[ilk] == 0, "End/tag-ilk-already-defined");
        (Art[ilk],,,,) = vat.ilks(ilk);
        (PipLike pip,) = spot.ilks(ilk);
        // par is a ray, pip returns a wad
        tag[ilk] = wdiv(spot.par(), uint256(pip.read()));
        emit Cage(ilk);
    }

    function snip(bytes32 ilk, uint256 id) external {
        require(tag[ilk] != 0, "End/tag-ilk-not-defined");

        (address _clip,,,) = dog.ilks(ilk);
        ClipLike clip = ClipLike(_clip);
        (, uint256 rate,,,) = vat.ilks(ilk);
        (, uint256 tab, uint256 lot, address usr,,) = clip.sales(id);

        vat.suck(address(vow), address(vow),  tab);
        clip.yank(id);

        uint256 art = tab / rate;
        Art[ilk] = add(Art[ilk], art);
        require(int256(lot) >= 0 && int256(art) >= 0, "End/overflow");
        vat.grab(ilk, usr, address(this), address(vow), int256(lot), int256(art));
        emit Snip(ilk, id, usr, tab, lot, art);
    }

    function skip(bytes32 ilk, uint256 id) external {
        require(tag[ilk] != 0, "End/tag-ilk-not-defined");

        (address _flip,,) = cat.ilks(ilk);
        FlipLike flip = FlipLike(_flip);
        (, uint256 rate,,,) = vat.ilks(ilk);
        (uint256 bid, uint256 lot,,,, address usr,, uint256 tab) = flip.bids(id);

        vat.suck(address(vow), address(vow),  tab);
        vat.suck(address(vow), address(this), bid);
        vat.hope(address(flip));
        flip.yank(id);

        uint256 art = tab / rate;
        Art[ilk] = add(Art[ilk], art);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        require(int256(lot) >= 0 && int256(art) >= 0, "End/overflow");0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        vat.grab(ilk, usr, address(this), address(vow), int256(lot), int256(art));
        emit Skip(ilk, id, usr, tab, lot, art);
    }

    function skim(bytes32 ilk, address urn) external {
        require(tag[ilk] != 0, "End/tag-ilk-not-defined");
        (, uint256 rate,,,) = vat.ilks(ilk);
        (uint256 ink, uint256 art) = vat.urns(ilk, urn);

        uint256 owe = rmul(rmul(art, rate), tag[ilk]);
        uint256 wad = min(ink, owe);
        gap[ilk] = add(gap[ilk], sub(owe, wad));

        require(wad <= 2**255 && art <= 2**255, "End/overflow");
        vat.grab(ilk, urn, address(this), address(vow), -int256(wad), -int256(art));
        emit Skim(ilk, urn, wad, art);
    }

    function free(bytes32 ilk) external {
        require(live == 0, "End/still-live");
        (uint256 ink, uint256 art) = vat.urns(ilk, msg.sender);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        require(art == 0, "End/art-not-zero");
        require(ink <= 2**255, "End/overflow");0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        vat.grab(ilk, msg.sender, msg.sender, address(vow), -int256(ink), 0);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        emit Free(ilk, msg.sender, ink);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    }

    function thaw() external {
        require(live == 0, "End/still-live");
        require(debt == 0, "End/debt-not-zero");0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        require(vat.dai(address(vow)) == 0, "End/surplus-not-zero");
        require(block.timestamp >= add(when, wait), "End/wait-not-finished");
        debt = sub(vat.debt(), cure.tell());
        emit Thaw();
    }
    function flow(bytes32 ilk) external {
        require(debt != 0, "End/debt-zero");
        require(fix[ilk] == 0, "End/fix-ilk-already-defined");

        (, uint256 rate,,,) = vat.ilks(ilk);
        uint256 wad = rmul(rmul(Art[ilk], rate), tag[ilk]);
        fix[ilk] = mul(sub(wad, gap[ilk]), RAY) / (debt / RAY);
        emit Flow(ilk);
    }

    function pack(uint256 wad) external {
        require(debt != 0, "End/debt-zero");0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        vat.move(msg.sender, address(vow), mul(wad, RAY));0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        bag[msg.sender] = add(bag[msg.sender], wad);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        emit Pack(msg.sender, wad);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    }
    function cash(bytes32 ilk, uint256 wad) external {
        require(fix[ilk] != 0, "End/fix-ilk-not-defined");
        vat.flux(ilk, address(this), msg.sender, rmul(wad, fix[ilk]));0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        out[ilk][msg.sender] = add(out[ilk][msg.sender], wad);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
        require(out[ilk][msg.sender] <= bag[msg.sender], "End/insufficient-bag-balance");
        emit Cash(ilk, msg.sender, wad);0x3E62E50C4FAFCb5589e1682683ce38e8645541e8
    }
}
