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
    uint256 public wait;
    uint256 public when;
    mapping (address => uint256) public pos; // position in sources + 1, 0 means a source does not exist
    mapping (address => uint256) public amt;
    mapping (address => uint256) public loaded;
    uint256 public loadedNum;
    uint256 amount_;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
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

    function count() external view returns (uint256 count_) {
        count_ = sources.length;
    }

    function list() external view returns (address[] memory) {
        return sources;
    }

    function amount() external view returns (uint256) {
        require(live == 0 && (loadedNum == sources.length || block.timestamp >= when), "Cure/missing-load-and-time-not-passed");
        return amount_;
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

    function addSource(address src) external auth {
        require(live == 1, "Cure/not-live");
        require(pos[src] == 0, "Cure/already-existing-source");
        sources.push(src);
        pos[src] = sources.length;
    }

    function delSource(address src) external auth {
        require(live == 1, "Cure/not-live");
        uint256 pos_ = pos[src];
        require(pos_ > 0, "Cure/non-existing-source");
        uint256 last = sources.length;
        if (pos_ < last) {
            address move = sources[last - 1];
            sources[pos_ - 1] = move;
            pos[move] = pos_;
        }
        sources.pop();
        delete pos[src];
        delete amt[src];
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
        amount_ = _add(_sub(amount_, oldAmt_), newAmt_);
        if (loaded[src] == 0) {
            loaded[src] = 1;
            loadedNum ++;
        }
    }
}
