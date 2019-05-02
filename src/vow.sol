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

contract Fusspot {
    function kick(address gal, uint lot, uint bid) public returns (uint);
    function dai() public returns (address);
}

contract Hopeful {
    function hope(address) public;
    function nope(address) public;
}

contract VatLike {
    function dai (address) public view returns (uint);
    function sin (address) public view returns (uint);
    function heal(uint) public;
}

contract Vow is DSNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) public note auth { wards[usr] = 1; }
    function deny(address usr) public note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }


    // --- Data ---
    address public vat;
    address public cow;  // flapper
    address public row;  // flopper

    mapping (uint48 => uint256) public sin; // debt queue
    uint256 public Sin;   // queued debt          [rad]
    uint256 public Ash;   // on-auction debt      [rad]

    uint256 public wait;  // flop delay           [rad]
    uint256 public sump;  // flop fixed lot size  [rad]
    uint256 public bump;  // flap fixed lot size  [rad]
    uint256 public hump;  // surplus buffer       [rad]

    // --- Init ---
    constructor() public { wards[msg.sender] = 1; }

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    function file(bytes32 what, uint data) public note auth {
        if (what == "wait") wait = data;
        if (what == "bump") bump = data;
        if (what == "sump") sump = data;
        if (what == "hump") hump = data;
    }
    function file(bytes32 what, address addr) public note auth {
        if (what == "flap") cow = addr;
        if (what == "flop") row = addr;
        if (what == "vat")  vat = addr;
    }

    // Total deficit
    function Awe() public view returns (uint) {
        return uint(VatLike(vat).sin(address(this)));
    }
    // Total surplus
    function Joy() public view returns (uint) {
        return uint(VatLike(vat).dai(address(this)));
    }
    // Unqueued, pre-auction debt
    function Woe() public view returns (uint) {
        return sub(sub(Awe(), Sin), Ash);
    }

    // Push to debt-queue
    function fess(uint tab) public note auth {
        sin[uint48(now)] = add(sin[uint48(now)], tab);
        Sin = add(Sin, tab);
    }
    // Pop from debt-queue
    function flog(uint48 era) public note {
        require(add(era, wait) <= now);
        Sin = sub(Sin, sin[era]);
        sin[era] = 0;
    }

    // Debt settlement
    function heal(uint rad) public note {
        require(rad <= Joy() && rad <= Woe());
        VatLike(vat).heal(rad);
    }
    function kiss(uint rad) public note {
        require(rad <= Ash && rad <= Joy());
        Ash = sub(Ash, rad);
        VatLike(vat).heal(rad);
    }

    // Debt auction
    function flop() public returns (uint id) {
        require(Woe() >= sump);
        require(Joy() == 0);
        Ash = add(Ash, sump);
        return Fusspot(row).kick(address(this), uint(-1), sump);
    }
    // Surplus auction
    function flap() public returns (uint id) {
        require(Joy() >= add(add(Awe(), bump), hump));
        require(Woe() == 0);
        Hopeful(Fusspot(cow).dai()).hope(cow);
        id = Fusspot(cow).kick(address(0), bump, 0);
        Hopeful(Fusspot(cow).dai()).nope(cow);
    }
}
