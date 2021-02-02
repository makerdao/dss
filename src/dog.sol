// SPDX-License-Identifier: AGPL-3.0-or-later

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

pragma solidity >=0.6.11;

interface ClipperLike {
    function kick(
        uint256 tab,
        uint256 lot,
        address usr,
        address kpr
    ) external returns (uint256);
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

contract Dog {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "Dog/not-authorized");
        _;
    }

    // --- Data ---
    struct Ilk {
        address clip;  // Liquidator
        uint256 chop;  // Liquidation Penalty                                          [wad]
        uint256 hole;  // Max DAI needed to cover debt+fees of active auctions per ilk [rad]
        uint256 dirt;  // Amt DAI needed to cover debt+fees of active auctions per ilk [rad]
    }

    VatLike immutable public vat;  // CDP Engine

    mapping (bytes32 => Ilk) public ilks;

    VowLike public vow;   // Debt Engine
    uint256 public live;  // Active Flag
    uint256 public Hole;  // Max DAI needed to cover debt+fees of active auctions [rad]
    uint256 public Dirt;  // Amt DAI needed to cover debt+fees of active auctions [rad]

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event FileUint256(bytes32 indexed what, uint256 data);
    event FileAddress(bytes32 indexed what, address data);
    event FileIlkUint256(bytes32 indexed ilk, bytes32 indexed what, uint256 data);
    event FileIlkClip(bytes32 indexed ilk, bytes32 indexed what, address clip);

    event Bark(
      bytes32 indexed ilk,
      address indexed urn,
      uint256 ink,
      uint256 art,
      uint256 due,
      address clip,
      uint256 indexed id
    );
    event Digs(bytes32 indexed ilk, uint256 rad);
    event Cage();

    // --- Init ---
    constructor(address vat_) public {
        vat = VatLike(vat_);
        live = 1;
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
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
    function file(bytes32 what, address data) external auth {
        if (what == "vow") vow = VowLike(data);
        else revert("Dog/file-unrecognized-param");
        emit FileAddress(what, data);
    }
    function file(bytes32 what, uint256 data) external auth {
        if (what == "Hole") Hole = data;
        else revert("Dog/file-unrecognized-param");
        emit FileUint256(what, data);
    }
    function file(bytes32 ilk, bytes32 what, uint256 data) external auth {
        if (what == "chop") ilks[ilk].chop = data;
        else if (what == "hole") ilks[ilk].hole = data;
        else revert("Dog/file-unrecognized-param");
        emit FileIlkUint256(ilk, what, data);
    }
    function file(bytes32 ilk, bytes32 what, address clip) external auth {
        if (what == "clip") ilks[ilk].clip = clip;
        else revert("Dog/file-unrecognized-param");
        emit FileIlkClip(ilk, what, clip);
    }

    function chop(bytes32 ilk) external view returns (uint256) {
        return ilks[ilk].chop;
    }

    // --- CDP Liquidation: all bark and no bite ---
    //
    // This function computes `tab`, the target amount of DAI to be raised in
    // an auction. In the general case, it is the product of the vault's
    // normalized debt, the collateral's accumulated rate, and the collateral's
    // `chop` value.
    //
    //     tab = vault.art * ilk.rate * ilk.chop
    //
    // When a liquidation is successfully started, its `tab` value is added to
    // the collateral's `dirt` value:
    //
    //     ilk.dirt' = ilk.dirt + tab
    //
    // To prevent too many liquidations from being triggered at once, the `tab`
    // value of new liquidations added to the collateral's `dirt` shouldn't
    // surpass the collateral's `hole` value:
    //
    //     tab + ilk.dirt <= ilk.hole
    //
    // Solving for tab,
    //
    //     tab <= ilk.hole - ilk.dirt
    //
    // There is also a general `Dirt` value that accumulates `tab`s from every
    // collateral, and a general `Hole` value for which the same condition
    // applies:
    //
    //     tab <= Hole - Dirt
    //
    // Joining the two equations above,
    //
    //     tab <= min(ilk.hole - ilk.dirt, Hole - Dirt)
    //
    // The debt of a vault is expressed in normalized terms:
    //
    //     vault.debt = vault.art * ilk.rate
    //
    // Furthermore, this debt is decreased after a liquidation is triggered:
    //
    //     vault.debt' = vault.debt - tab
    //
    // However, the new debt value cannot be lower than the collateral's `dust`:
    //
    //     vault.debt' >= ilk.dust
    //
    // Solving for `tab` in the two equations above,
    //
    //     vault.debt - tab >= ilk.dust
    //     -tab >= ilk.dust - vault.debt
    //     tab <= vault.debt - ilk.dust
    //     tab <= vault.art * ilk.rate - ilk.dust
    //
    // That is, unless the new debt value is zero:
    //
    //     vault.debt' = 0
    //
    // Solving for `tab` again,
    //
    //     vault.debt - tab = 0
    //     tab = vault.debt
    //     tab = vault.art * ilk.rate
    //
    // In summary, `tab` is computed with the following formula:
    //
    //     tab = vault.art * ilk.rate * ilk.chop
    //
    // And is subject to the following conditions:
    //
    //     tab <= min(ilk.hole - ilk.dirt, Hole - Dirt)
    //     tab <= vault.art * ilk.rate - ilk.dust || tab = vault.art * ilk.rate
    //
    function bark(bytes32 ilk, address urn, address kpr) external returns (uint256 id) {
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

            // Get the minimum value between:
            // 1) Remaining space in the general Hole
            // 2) Remaining space in the collateral hole
            uint256 room = min(sub(Hole, Dirt), sub(milk.hole, milk.dirt));

            // Verify there is room and it is not dusty
            require(room > 0 && room >= dust, "Dog/liquidation-limit-hit");

            // uint256.max()/(RAD*WAD) = 115,792,089,237,316
            dart = min(art, mul(room, WAD) / rate / milk.chop);

            if (mul(art - dart, rate) < dust) {
                // avoid leaving a dusty vault to prevent unliquidatable vaults
                dart = art;
            }
        }

        uint256 dink = mul(ink, dart) / art;

        require(dink > 0, "Dog/null-auction");
        require(dart <= 2**255 && dink <= 2**255, "Dog/overflow");

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
                usr: urn,
                kpr: kpr
            });
        }

        emit Bark(ilk, urn, dink, dart, due, milk.clip, id);
    }

    function digs(bytes32 ilk, uint256 rad) external auth {
        Dirt = sub(Dirt, rad);
        ilks[ilk].dirt = sub(ilks[ilk].dirt, rad);
        emit Digs(ilk, rad);
    }

    function cage() external auth {
        live = 0;
        emit Cage();
    }
}
