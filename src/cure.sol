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
    address[] public srcs;
    uint256 public wait;
    uint256 public when;
    mapping (address => uint256) public pos; // position in srcs + 1, 0 means a source does not exist
    mapping (address => uint256) public amt;
    mapping (address => uint256) public loaded;
    uint256 public lCount;
    uint256 public say;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event Lift(address indexed src);
    event Drop(address indexed src);
    event Load(address indexed src);
    event Cage();

    modifier auth {
        require(wards[msg.sender] == 1, "Cure/not-authorized");
        _;
    }

    // --- Internal ---
    function _add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Cure/add-overflow");
    }

    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Cure/sub-underflow");
    }

    constructor() public {
        live = 1;
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function tCount() external view returns (uint256 count_) {
        count_ = srcs.length;
    }

    function list() external view returns (address[] memory) {
        return srcs;
    }

    function tell() external view returns (uint256) {
        require(live == 0 && (lCount == srcs.length || block.timestamp >= when), "Cure/missing-load-and-time-not-passed");
        return say;
    }

    function rely(address usr) external auth {
        require(live == 1, "Cure/not-live");
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        require(live == 1, "Cure/not-live");
        wards[usr] = 0;
        emit Deny(usr);
    }

    function file(bytes32 what, uint256 data) external auth {
        require(live == 1, "Cure/not-live");
        if (what == "wait") wait = data;
        else revert("Cure/file-unrecognized-param");
        emit File(what, data);
    }

    function lift(address src) external auth {
        require(live == 1, "Cure/not-live");
        require(pos[src] == 0, "Cure/already-existing-source");
        srcs.push(src);
        pos[src] = srcs.length;
        emit Lift(src);
    }

    function drop(address src) external auth {
        require(live == 1, "Cure/not-live");
        uint256 pos_ = pos[src];
        require(pos_ > 0, "Cure/non-existing-source");
        uint256 last = srcs.length;
        if (pos_ < last) {
            address move = srcs[last - 1];
            srcs[pos_ - 1] = move;
            pos[move] = pos_;
        }
        srcs.pop();
        delete pos[src];
        delete amt[src];
        emit Drop(src);
    }

    function cage() external auth {
        require(live == 1, "Cure/not-live");
        live = 0;
        when = _add(block.timestamp, wait);
        emit Cage();
    }

    function load(address src) external {
        require(live == 0, "Cure/still-live");
        require(pos[src] > 0, "Cure/non-existing-source");
        uint256 oldAmt_ = amt[src];
        uint256 newAmt_ = amt[src] = SourceLike(src).cure();
        say = _add(_sub(say, oldAmt_), newAmt_);
        if (loaded[src] == 0) {
            loaded[src] = 1;
            lCount++;
        }
        emit Load(src);
    }
}
