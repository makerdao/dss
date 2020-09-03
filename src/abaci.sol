// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.5.12;

// interface Abacus {
//     // 1st arg: initial price           [ray]
//     // 2nd arg: auction start timestamp [Unix epoch]
//     // returns: current auction price   [ray]
//     function price(uint256, uint256) external view returns (uint256);
// }

contract LinearDecrease /* is Abacus */ {

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external /* note */ auth { wards[usr] = 1; }
    function deny(address usr) external /* note */ auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "LinearDecrease/not-authorized");
        _;
    }

    // --- Data ---
    uint256 tau;  // seconds after auction start when the price reaches zero [seconds]

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external auth {
        if (what ==  "tau") tau = data;
        else revert("LinearDecrease/file-unrecognized-param");
    }

    // --- Math ---
    uint256 constant RAY = 10 ** 27;
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / RAY;
    }

    function price(uint256 top, uint256 tic) external view returns (uint256) {
        uint256 end = tic + tau;
        if (now >= end) return 0;
        return rmul(top, mul(end - now, RAY) / tau);
    }
}

contract StairstepExponentialDecrease /* is Abacus */ {

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external /* note */ auth { wards[usr] = 1; }
    function deny(address usr) external /* note */ auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "StairstepExponentialDecrease/not-authorized");
        _;
    }

    // --- Data ---
    uint256 public step; // Length of time between price drops        [seconds]
    uint256 public cut;  // Per-step multiplicative decrease in price [ray]

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
        cut  = 0;
        step = 1;
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external auth {
        if      (what ==  "cut") cut  = data;
        else if (what == "step") step = data;
        else revert("StairstepExponentialDecrease/file-unrecognized-param");
    }

    // --- Math ---
    uint256 constant RAY = 10 ** 27;
    function sub(uint x, uint y) internal pure returns (uint z) {
        z = x - uint(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / RAY;
    }
    // optimized version from dss PR #78
    function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
        assembly {
            switch n case 0 { z := b }
            default {
                switch x case 0 { z := 0 }
                default {
                    switch mod(n, 2) case 0 { z := b } default { z := x }
                    let half := div(b, 2)  // for rounding.
                    for { n := div(n, 2) } n { n := div(n,2) } {
                        let xx := mul(x, x)
                        if shr(128, x) { revert(0,0) }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) { revert(0,0) }
                        x := div(xxRound, b)
                        if mod(n,2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) { revert(0,0) }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }

    function price(uint256 top, uint256 tic) external view returns (uint256) {
        return rmul(top, rpow(sub(RAY, cut), sub(now, uint256(tic)) / step, RAY));
    }
}
