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

interface SourceLike {
    function cure() external view returns (uint256);
}

contract Cure {
    mapping (address => uint256) public wards;
    uint256 public live;
    address[] public sources;
    uint256 public total;
    mapping (address => Source) public data;

    struct Source {
        uint128 pos;
        uint128 amt;
    }

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
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
    function _add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Cure/add-overflow");
    }

    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Cure/sub-underflow");
    }

    function _toUint128(uint256 x) internal pure returns (uint128 y) {
        require((y = uint128(x)) == x, "Cure/toUint128-overflow");
    }

    constructor() public {
        live = 1;
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function sLength() external view returns (uint256 size) {
        size = sources.length;
    }

    function rely(address usr) external auth isLive {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth isLive {
        wards[usr] = 0;
        emit Deny(usr);
    }

    function addSource(address src) external auth isLive {
        Source storage data_ = data[src];
        require(data_.pos == 0, "Cure/already-existing-source");
        sources.push(src);
        data_.pos = _toUint128(sources.length);
        data_.amt = _toUint128(SourceLike(src).cure());
        if (data_.amt > 0) {
            total = _add(total, data_.amt);
        }
    }

    function delSource(address src) external auth isLive {
        Source memory data_ = data[src];
        require(data_.pos > 0, "Cure/non-existing-source");
        uint256 last = sources.length;
        if (data_.pos < last) {
            address move = sources[last - 1];
            sources[data_.pos - 1] = move;
            data[move].pos = data_.pos;
        }
        delete data[src];
        sources.pop();
        if (data_.amt > 0) {
            total = _sub(total, data_.amt);
        }
    }

    function cage() external auth isLive {
        live = 0;
        emit Cage();
    }

    function reset(address src) external {
        uint256 amt = data[src].amt;
        if (amt > 0) {
            total = _sub(total, amt);
        }
    data[src].amt = amt = _toUint128(SourceLike(src).cure());
    if (amt > 0) {
        total = _add(total, amt);   
    }
    }
}
