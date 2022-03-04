// SPDX-License-Identifier: AGPL-3.0-or-later

/// bow.sol -- Dai settlement module

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
// Copyright (C) 2021-2022 Dai Foundation
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

pragma solidity >=0.6.12;

interface FlopLike {
    function kick(address gal, uint256 lot, uint256 bid) external returns (uint256);
    function cage() external;
    function live() external returns (uint256);
}

interface FlapLike {
    function kick(uint256 lot, uint256 bid) external returns (uint256);
    function cage(uint256) external;
    function live() external returns (uint256);
}

interface VatLike {
    function dai (address) external view returns (uint256);
    function sin (address) external view returns (uint256);
    function heal(uint256) external;
    function hope(address) external;
    function nope(address) external;
    function move(address, address, uint256) external;
}

interface VowLike {
    function heal(uint256) external;
}

contract Bow {

    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth { require(live == 1, "Bow/not-live"); wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "Bow/not-authorized");
        _;
    }

    // --- Data ---
    VatLike public immutable vat;   // CDP Engine
    address public immutable vow;   // System accounting
    FlapLike public flapper;        // Surplus Auction House
    FlopLike public flopper;        // Debt Auction House

    mapping (uint256 => uint256) public sin;  // debt queue
    uint256 public Sin;   // Queued debt            [rad]
    uint256 public Ash;   // On-auction debt        [rad]

    uint256 public wait;  // Flop delay             [seconds]
    uint256 public dump;  // Flop initial lot size  [wad]
    uint256 public sump;  // Flop fixed bid size    [rad]

    uint256 public bump;  // Flap fixed lot size    [rad]
    uint256 public hump;  // Surplus buffer         [rad]

    uint256 public live;  // Active Flag

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    // --- Init ---
    constructor(address vat_, address vow_, address flapper_, address flopper_) public {
        vat     = VatLike(vat_);
        vow     = vow_;
        flapper = FlapLike(flapper_);
        flopper = FlopLike(flopper_);

        VatLike(vat_).hope(flapper_);
        live = 1;
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Math ---
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external auth {
        if (what == "wait") wait = data;
        else if (what == "bump") bump = data;
        else if (what == "sump") sump = data;
        else if (what == "dump") dump = data;
        else if (what == "hump") hump = data;
        else revert("Bow/file-unrecognized-param");
    }

    function file(bytes32 what, address data) external auth {
        if (what == "flapper") {
            vat.nope(address(flapper));
            flapper = FlapLike(data);
            vat.hope(data);
        }
        else if (what == "flopper") flopper = FlopLike(data);
        else revert("Bow/file-unrecognized-param");
    }

    // Push to debt-queue
    function fess(uint256 tab) external auth {
        sin[block.timestamp] = add(sin[block.timestamp], tab);
        Sin = add(Sin, tab);
    }
    // Pop from debt-queue
    function flog(uint256 era) external {
        require(add(era, wait) <= block.timestamp, "Bow/wait-not-finished");
        Sin = sub(Sin, sin[era]);
        sin[era] = 0;
    }

    // Debt settlement
    function kiss(uint256 rad) external {
        require(rad <= Ash, "Bow/not-enough-ash");
        require(rad <= vat.dai(vow), "Bow/insufficient-surplus");
        Ash = sub(Ash, rad);
        vat.heal(rad);
    }

    // Debt auction
    function flop() external returns (uint256 id) {
        require(sump <= sub(sub(vat.sin(vow), Sin), Ash), "Bow/insufficient-debt");
        require(vat.dai(vow) == 0, "Bow/surplus-not-zero");
        Ash = add(Ash, sump);
        id = flopper.kick(vow, dump, sump);
    }
    // Surplus auction
    function flap() external returns (uint256 id) {
        require(vat.dai(vow) >= add(add(vat.sin(vow), bump), hump), "Bow/insufficient-surplus");
        require(sub(sub(vat.sin(vow), Sin), Ash) == 0, "Bow/debt-not-zero");
        vat.move(msg.sender, address(this), bump);
        id = flapper.kick(bump, 0);
    }

    function cage() external auth {
        require(live == 1, "Bow/not-live");
        live = 0;
        Sin = 0;
        Ash = 0;
        flapper.cage(vat.dai(address(flapper)));
        flopper.cage();
        VowLike(vow).heal(min(vat.dai(vow), vat.sin(vow)));
    }
}
