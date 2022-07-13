// SPDX-License-Identifier: AGPL-3.0-or-later

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

pragma solidity ^0.6.12;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

contract Vat {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { require(live == 1, "Vat/not-live"); wards[usr] = 1; }
    function deny(address usr) external auth { require(live == 1, "Vat/not-live"); wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Vat/not-authorized");
        _;
    }   

    mapping(address => mapping (address => uint)) public can;
    function hope(address usr) external { can[msg.sender][usr] = 1; }
    function nope(address usr) external { can[msg.sender][usr] = 0; }
    function wish(address bit, address usr) internal view returns (bool) {
        return either(bit == usr, can[bit][usr] == 1);
    }

    // --- Data ---
    struct Ilk {
        uint256 Art;   // Total Normalised Debt     [wad]           // DAM: Also takes into account interest when Vat.fold has been called.
        uint256 rate;  // Accumulated Rates         [ray]           // DAM: The accumulated change in interest since the last time Vat.fold was called.
        uint256 spot;  // Price with Safety Margin  [ray]           // DAM: For pricing the collateral vs DAI.
        uint256 line;  // Debt Ceiling              [rad]           // DAM: Total amount of debt/DAI allowed per this collateral type.
        uint256 dust;  // Urn Debt Floor            [rad]           // DAM: Minimum amount of debt for a specfic vault.
    }
    struct Urn {
        uint256 ink;   // Locked Collateral  [wad]                  // DAM: Total amount of collateral locked of a particular type for this user.
        uint256 art;   // Normalised Debt    [wad]                  // DAM: Total debt/dai for this user's particular Urn. Note: they may have multiple Urn's one for each collateral type.
    }

    mapping (bytes32 => Ilk)                       public ilks;             // DAM: Map of collateral id to collateral.
    mapping (bytes32 => mapping (address => Urn )) public urns;             // DAM: Map of collateral id to address to vault.                   E.g. urns["eth"]["0xblah"]
    mapping (bytes32 => mapping (address => uint)) public gem;  // [wad]    // DAM: Map of collateral id to address to amount of collateral.    E.g  gem["eth"]["0xfoo"]
    mapping (address => uint256)                   public dai;  // [rad]    // DAM: DAI balance for each user. Should equal "art" amount?
    mapping (address => uint256)                   public sin;  // [rad]    // DAM: Total amount of unbacked DAI for the protocol as a whole.

    uint256 public debt;  // Total Dai Issued    [rad]                      // DAM: Sum of issued DAI for each address.
    uint256 public vice;  // Total Unbacked Dai  [rad]                      // DAM: Sum of unbacked DAI for each address.
    uint256 public Line;  // Total Debt Ceiling  [rad]                      // DAM: Protocol debt ceiling.
    uint256 public live;  // Active Flag

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
        live = 1;
    }

    // --- Math ---
    function _add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }
    function _sub(uint x, int y) internal pure returns (uint z) {
        z = x - uint(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }
    function _mul(uint x, int y) internal pure returns (int z) {
        z = int(x) * y;
        require(int(x) >= 0);
        require(y == 0 || z / y == int(x));
    }
    function _add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function _sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function _mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    function init(bytes32 ilk) external auth {
        require(ilks[ilk].rate == 0, "Vat/ilk-already-init");
        ilks[ilk].rate = 10 ** 27;
    }
    function file(bytes32 what, uint data) external auth {
        require(live == 1, "Vat/not-live");
        if (what == "Line") Line = data;
        else revert("Vat/file-unrecognized-param");
    }
    function file(bytes32 ilk, bytes32 what, uint data) external auth {
        require(live == 1, "Vat/not-live");
        if (what == "spot") ilks[ilk].spot = data;
        else if (what == "line") ilks[ilk].line = data;
        else if (what == "dust") ilks[ilk].dust = data;
        else revert("Vat/file-unrecognized-param");
    }
    function cage() external auth {
        live = 0;
    }

    // --- Fungibility ---
    // For updating a user's unlocked collateral balance. E.g. this is called when they deposit or withdrawl unlocked collateral.
    function slip(bytes32 ilk, address usr, int256 wad) external auth {
        gem[ilk][usr] = _add(gem[ilk][usr], wad);
    }

    // For moving collateral from one address to another.
    function flux(bytes32 ilk, address src, address dst, uint256 wad) external {
        require(wish(src, msg.sender), "Vat/not-allowed");
        gem[ilk][src] = _sub(gem[ilk][src], wad);
        gem[ilk][dst] = _add(gem[ilk][dst], wad);
    }

    // For moving DAI from one address to another.
    function move(address src, address dst, uint256 rad) external {
        require(wish(src, msg.sender), "Vat/not-allowed");
        dai[src] = _sub(dai[src], rad);
        dai[dst] = _add(dai[dst], rad);
    }

    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- CDP Manipulation ---
    // This is the main function for locking or unlokcing collateral and thus minting or burning DAI.
    // i    -> collateral type.
    // dink -> change in collateral. Can be negative.
    // dart -> change in debt (dai). Can be negative.
    //
    // 1 Scenario: Opening a vualt for the first time at time zero.
    // Assumption: We do this at time zero. Interest rate is 5% annualised.
    // i       = "eth"
    // u, v, w = 0xROG
    // dink    = 1 eth
    // dart    = 100 dai
    // 1 eth is added to locked collateral and 100 dai is added to debt for the user's Urn and the total debt for the collateral type.
    // No interest has yet accrued as we are at time zero. "dtab" is just "dart" and "tab" is zero.
    // The total debt is updated with the "dart" amount.
    // The gem balance for the user is reduced by the "dink" amount.
    // The "dai" balance for the user is increased by the "dart" amount.
    // 
    // 2 Scenario: Add 0.5 more eth after 6 months. 
    // Assumptions: Price of eth doesn't change. Vat.fold has literally just been called. before the call to "frob".
    // When Vat.fold was called, the overall debt balance is updated to reflect 6 motnhs of interest on 1 eth, which is: 2.4695076595959808.
    // So overall debt before Vat.frob is called now is 102.4695076595959808.
    // Now we call Vat.frob
    // i       = "eth"
    // u, v, w = 0xROG
    // dink    = 0.5 eth
    // dart    = 50 dai
    // User's collateral updated with 0.5 eth so it is now 1.5 eth. total debt is updated to be 150.
    // When Vat.fold was called, 6 months of accrued interest on the eth collateral (as a whole) was recognised. At this point, individual urns have not yet been updated.
    // The ilk.rate for eth is now 1.05^(6/12) = 1.0246950765959598. The rate was 1 and now 0.02469... has been added to it.
    // dart is multiplied by the rate above to get the normalised amount for this time period = 51.2347538297979904. (We need this number: 1.234... later...)
    // ink is now 1.5 eth
    // art is now 150 dai
    // debt is now 102.4695076595959808 + 51.2347538297979904 = 153.7042614893939712.
    // gem eth balance for user is 0.
    // dai balance for user is 153.7042614893939712
    // Remove 0.5 eth from the users unlocked collateral balance.
    // Update the user's DAI balance.
    // 
    // 3 Scenario: Paying down 1.5 eth of a vault after 1 year.
    // Assumptions: Price of eth doesn't change. Vat.fold has literally just been called. before the call to "frob".
    // When Vat.fold is called. The rate diff is 0.0253049234040401, so we do 0.0253049234040401 x 150 to get the accrued interest since the last 6 months.
    // That number is 3.7957385106060195. So total debt is now: 153.7042614893939712 + 3.7957385106060195 = 157.4999999999999907
    // But this debt number assumes that all collateral existed in the vault for the whole period... 
    // i        = "eth"
    // u, v, w  = 0xROG
    // dink     = -1 eth
    // dart     = -100 dai
    // So...
    // urn.ink  -> 1.5 - 1.5     = 0
    // urn.art  -> 150 - 150     = 0
    // urn.rate -> 1.05
    // dtab     -> 1.05 x -150   = -157.5 .... This is saying if we want to redeem 1.5 eth after one year we need to repay 107.5 DAI.
    // tab      -> 1.05 x 0      = 0      .... There's nothing left in the vault.
    // debt     -> 157.5 - 157.5 = 0
    // Gem balance gets updated with 1.5 eth.
    // 157.5 dai is substracted from the user's DAI balance.
    // But wait... the interest on 100 DAI over 1 year and 50 DAI over half a year is not 7.5 DAI. It is actually: ((1.05^(6/12)*50)-50)+(1.05*100) = 106.2347538297979904
    // The difference between 106.2347538297979904 and 157.5 is the extra 1.2347538297979904 DAI whch was given to the user when they locked up a further 0.5 eth.
    function frob(bytes32 i, address u, address v, address w, int dink, int dart) external {
        // system is live
        require(live == 1, "Vat/not-live");

        Urn memory urn = urns[i][u];                    // DAM: The user's vault.
        Ilk memory ilk = ilks[i];                       // DAM: Data for this collateral type.
        // ilk has been initialised
        require(ilk.rate != 0, "Vat/ilk-not-init");

        urn.ink = _add(urn.ink, dink);                  // DAM: Add the change in collateral to the total locked up for that collateral type.
        urn.art = _add(urn.art, dart);                  // DAM: Add the change in debt to the user's vault.
        ilk.Art = _add(ilk.Art, dart);                  // DAM: Update the total debt for the collateral type.

        int dtab = _mul(ilk.rate, dart);                // DAM: Calculate what the normalised change in debt should be.
        uint tab = _mul(ilk.rate, urn.art);             // DAM: Calculate the interset on the existing debt.
        debt     = _add(debt, dtab);                    // DAM: Update the total normalised debt with the new normalised change.

        // either debt has decreased, or debt ceilings are not exceeded
        require(either(dart <= 0, both(_mul(ilk.Art, ilk.rate) <= ilk.line, debt <= Line)), "Vat/ceiling-exceeded");
        // urn is either less risky than before, or it is safe
        require(either(both(dart <= 0, dink >= 0), tab <= _mul(urn.ink, ilk.spot)), "Vat/not-safe");

        // urn is either more safe, or the owner consents
        require(either(both(dart <= 0, dink >= 0), wish(u, msg.sender)), "Vat/not-allowed-u");
        // collateral src consents
        require(either(dink <= 0, wish(v, msg.sender)), "Vat/not-allowed-v");
        // debt dst consents
        require(either(dart >= 0, wish(w, msg.sender)), "Vat/not-allowed-w");

        // urn has no debt, or a non-dusty amount
        require(either(urn.art == 0, tab >= ilk.dust), "Vat/dust");

        gem[i][v] = _sub(gem[i][v], dink);              // DAM: Either debits or credits unlocked collateral. Whether dink is positive or negative.
        dai[w]    = _add(dai[w],    dtab);              // DAM: Update the user's DAI balance.

        urns[i][u] = urn;                               // DAM: Update the urn and ilk.
        ilks[i]    = ilk;
    }
    // --- CDP Fungibility ---
    // This is for splitting a vault.
    function fork(bytes32 ilk, address src, address dst, int dink, int dart) external {
        Urn storage u = urns[ilk][src];
        Urn storage v = urns[ilk][dst];
        Ilk storage i = ilks[ilk];

        u.ink = _sub(u.ink, dink);
        u.art = _sub(u.art, dart);
        v.ink = _add(v.ink, dink);
        v.art = _add(v.art, dart);

        uint utab = _mul(u.art, i.rate);
        uint vtab = _mul(v.art, i.rate);

        // both sides consent
        require(both(wish(src, msg.sender), wish(dst, msg.sender)), "Vat/not-allowed");

        // both sides safe
        require(utab <= _mul(u.ink, i.spot), "Vat/not-safe-src");
        require(vtab <= _mul(v.ink, i.spot), "Vat/not-safe-dst");

        // both sides non-dusty
        require(either(utab >= i.dust, u.art == 0), "Vat/dust-src");
        require(either(vtab >= i.dust, v.art == 0), "Vat/dust-dst");
    }
    // --- CDP Confiscation ---
    // This is alled when there is a liquidation.
    function grab(bytes32 i, address u, address v, address w, int dink, int dart) external auth {
        Urn storage urn = urns[i][u];
        Ilk storage ilk = ilks[i];

        urn.ink = _add(urn.ink, dink);
        urn.art = _add(urn.art, dart);
        ilk.Art = _add(ilk.Art, dart);

        int dtab = _mul(ilk.rate, dart);

        gem[i][v] = _sub(gem[i][v], dink);
        sin[w]    = _sub(sin[w],    dtab);
        vice      = _sub(vice,      dtab);
    }

    // --- Settlement ---
    function heal(uint rad) external {
        address u = msg.sender;
        sin[u] = _sub(sin[u], rad);
        dai[u] = _sub(dai[u], rad);
        vice   = _sub(vice,   rad);
        debt   = _sub(debt,   rad);
    }
    function suck(address u, address v, uint rad) external auth {
        sin[u] = _add(sin[u], rad);
        dai[v] = _add(dai[v], rad);
        vice   = _add(vice,   rad);
        debt   = _add(debt,   rad);
    }

    // --- Rates ---
    // This recognises the accrued interest to date.
    function fold(bytes32 i, address u, int rate) external auth {           // DAM: This is always called with `u` being the "vow" or protocol treasury.
        require(live == 1, "Vat/not-live");
        Ilk storage ilk = ilks[i];                                          // DAM: Get the collateral type.
        ilk.rate = _add(ilk.rate, rate);                                    // DAM: Add the rate from the param  (which is the difference between the previous rate and the new rate) to the current rate.
        int rad  = _mul(ilk.Art, rate);                                     // DAM: Calcualate the new accrued interest. Note that we use `rate` instead of `rad`.
        dai[u]   = _add(dai[u], rad);                                       // DAM: Add the accrued interest to vow's DAI balance. Which also grosses up the total DAI balance.
        debt     = _add(debt,   rad);                                       // DAM: Add the accrued interest to the total debt balance. As an aside, total debt should equal total outstanding DAI.
    }
}
