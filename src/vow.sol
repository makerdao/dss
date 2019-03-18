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

import "ds-note/note.sol";

contract Fusspot {
    function kick(address gal, uint lot, uint bid) public returns (uint);
    function dai() public returns (address);
}

contract Hopeful {
    function hope(address) public;
    function nope(address) public;
}

contract VatLike {
    function dai (bytes32) public view returns (uint);
    function sin (bytes32) public view returns (uint);
    function heal(bytes32,bytes32,int) public;
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
    uint256 public Sin;   // queued debt
    uint256 public Ash;   // on-auction debt

    uint256 public wait;  // flop delay
    uint256 public sump;  // flop fixed lot size
    uint256 public bump;  // flap fixed lot size
    uint256 public hump;  // surplus buffer

    // --- Init ---
    constructor() public { wards[msg.sender] = 1; }

    // --- Math ---
    uint256 constant ONE = 10 ** 27;

    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        z = x - y;
        require(z <= x);
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
        return uint(VatLike(vat).sin(bytes32(bytes20(address(this))))) / ONE;
    }
    // Total surplus
    function Joy() public view returns (uint) {
        return uint(VatLike(vat).dai(bytes32(bytes20(address(this))))) / ONE;
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
    function heal(uint wad) public note {
        require(wad <= Joy() && wad <= Woe());
        require(int(mul(wad, ONE)) >= 0);
        VatLike(vat).heal(bytes32(bytes20(address(this))), bytes32(bytes20(address(this))), int(mul(wad, ONE)));
    }
    function kiss(uint wad) public note {
        require(wad <= Ash && wad <= Joy());
        Ash = sub(Ash, wad);
        require(int(mul(wad, ONE)) >= 0);
        VatLike(vat).heal(bytes32(bytes20(address(this))), bytes32(bytes20(address(this))), int(mul(wad, ONE)));
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
