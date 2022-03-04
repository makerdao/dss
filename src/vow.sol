// SPDX-License-Identifier: AGPL-3.0-or-later

/// vow.sol -- Dai system accounting module

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

pragma solidity >=0.6.12;

interface VatLike {
    function heal(uint256) external;
    function hope(address) external;
    function nope(address) external;
}

contract Vow {

    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "Vow/not-authorized");
        _;
    }

    // --- Data ---
    VatLike public immutable vat;

    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Hope(address indexed usr);
    event Nope(address indexed usr);
    event Heal(uint256 rad);

    // --- Init ---
    constructor(address vat_) public {
        vat = VatLike(vat_);

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Admin ---
    function hope(address who) external auth {
        vat.hope(who);
        emit Hope(who);
    }
    function nope(address who) external auth {
        vat.nope(who);
        emit Nope(who);
    }

    // --- Debt Settlement ---
    function heal(uint256 rad) external {
        vat.heal(rad);
        emit Heal(rad);
    }

}
