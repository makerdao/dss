/// vow.sol -- Dai settlement module

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

import "./lib.sol";

contract Flopper {
    function kick(address gal, uint lot, uint bid) public returns (uint);
    function cage() public;
    function live() public returns (uint);
}

contract Flapper {
    function kick(uint lot, uint bid) public returns (uint);
    function cage(uint) public;
    function live() public returns (uint);
}

contract VatLike {
    function dai (address) public view returns (uint);
    function sin (address) public view returns (uint);
    function heal(uint256) public;
    function hope(address) public;
}

contract Vow is DSNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) public note auth { wards[usr] = 1; }
    function deny(address usr) public note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- Data ---
    VatLike public vat;
    Flapper public flapper;
    Flopper public flopper;

    mapping (uint256 => uint256) public sin; // debt queue
    uint256 public Sin;   // queued debt          [rad]
    uint256 public Ash;   // on-auction debt      [rad]

    uint256 public wait;  // flop delay           [rad]
    uint256 public sump;  // flop fixed lot size  [rad]
    uint256 public bump;  // flap fixed lot size  [rad]
    uint256 public hump;  // surplus buffer       [rad]

    uint256 public live;

    // --- Init ---
    constructor(address vat_, address flapper_, address flopper_) public {
        wards[msg.sender] = 1;
        vat     = VatLike(vat_);
        flapper = Flapper(flapper_);
        flopper = Flopper(flopper_);
        vat.hope(flapper_);
        live = 1;
    }

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }

    // --- Administration ---
    function file(bytes32 what, uint data) public note auth {
        if (what == "wait") wait = data;
        if (what == "bump") bump = data;
        if (what == "sump") sump = data;
        if (what == "hump") hump = data;
    }

    // Push to debt-queue
    function fess(uint tab) public note auth {
        sin[now] = add(sin[now], tab);
        Sin = add(Sin, tab);
    }
    // Pop from debt-queue
    function flog(uint era) public note {
        require(add(era, wait) <= now);
        Sin = sub(Sin, sin[era]);
        sin[era] = 0;
    }

    // Debt settlement
    function heal(uint rad) public note {
        require(rad <= vat.dai(address(this)));
        require(rad <= sub(sub(vat.sin(address(this)), Sin), Ash));
        vat.heal(rad);
    }
    function kiss(uint rad) public note {
        require(rad <= Ash);
        require(rad <= vat.dai(address(this)));
        Ash = sub(Ash, rad);
        vat.heal(rad);
    }

    // Debt auction
    function flop() public note returns (uint id) {
        require(sump <= sub(sub(vat.sin(address(this)), Sin), Ash));
        require(vat.dai(address(this)) == 0);
        Ash = add(Ash, sump);
        id = flopper.kick(address(this), uint(-1), sump);
    }
    // Surplus auction
    function flap() public note returns (uint id) {
        require(vat.dai(address(this)) >= add(add(vat.sin(address(this)), bump), hump));
        require(sub(sub(vat.sin(address(this)), Sin), Ash) == 0);
        id = flapper.kick(bump, 0);
    }

    function cage() public note auth {
        live = 0;
        Sin = 0;
        Ash = 0;
        flapper.cage(vat.dai(address(flapper)));
        flopper.cage();
        vat.heal(min(vat.dai(address(this)), vat.sin(address(this))));
    }
}
