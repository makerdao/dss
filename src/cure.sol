// SPDX-License-Identifier: AGPL-3.0-or-later

/// cure.sol -- Debt Rectifier contract

// Copyright (C) 2022 Dai Foundation
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
    function debt() external view returns (uint256);
}

interface SourceLike {
    function cure() external view returns (uint256);
}

contract Cure {
    mapping (address => uint256) public wards;
    uint256 public live;
    uint256 public cure;
    address[] public sources;

    VatLike public immutable vat;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event Cage();

    modifier auth {
        require(wards[msg.sender] == 1, "Cure/not-authorized");
        _;
    }

    modifier isLive {
        require(live == 1, "Cure/not-live");
        _;
    }

    // --- Internal ---
    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    constructor(address vat_) public {
        live = 1;
        vat = VatLike(vat_);
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Auth ---
    function rely(address usr) external auth isLive {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth isLive {
        wards[usr] = 0;
        emit Deny(usr);
    }

    function file(bytes32 what, uint256 data) external auth isLive {
        if (what == "cure") cure = data;
        else revert("Cure/file-unrecognized-param");
        emit File(what, data);
    }

    function addSource(address src_) external auth isLive {
        sources.push(src_);
    }

    function delSource(uint256 index) external auth isLive {
        uint256 length = sources.length;
        require(index < length, "Cure/non-existing-index");
        uint256 last = length - 1;
        if (index < last) {
            address move = sources[last];
            sources[index] = move;
        }
        sources.pop();
    }

    function cage() external auth {
        live = 0;
        emit Cage();
    }

    // --- Getters ---
    function numSources() external view returns (uint256 size) {
        size = sources.length;
    }

    function debt() external view returns (uint256 debt_) {
        debt_ = _sub(vat.debt(), cure);

        for (uint256 i; i < sources.length; i++) {
            debt_ = _sub(debt_, SourceLike(sources[i]).cure());
        }
    }
}
