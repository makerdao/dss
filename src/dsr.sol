/// dsr.sol -- Dai Savings Rate

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

/*
   "Savings Dai" is obtained when Dai is deposited into
   this contract. Each "Savings Dai" accrues Dai interest
   at the "Dai Savings Rate".

   This contract does not implement a user tradeable token
   and is intended to be used with adapters.

         --- `save` your `dai` in the `pot` ---

   - `dsr`: the Dai Savings Rate
   - `pie`: user balance of Savings Dai

   - `save`: deposit / withdraw savings dai
   - `drip`: perform rate collection
   - `move`: transfer savings dai (for use by adapters)

*/

contract VatLike {
    function move(bytes32,bytes32,int256) public;
    function heal(bytes32,bytes32,int256) public;
}

contract Pot is DSNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) public note auth { wards[guy] = 1; }
    function deny(address guy) public note auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- Data ---
    mapping (bytes32 => uint256) public pie;  // user Savings Dai

    uint256 public Pie;  // total Savings Dai
    uint256 public dsr;  // The Dai Savings Rate
    uint256 public chi;  // The Rate Accumulator

    VatLike public vat;  // CDP engine
    bytes32 public vow;  // Debt engine
    uint48  public rho;  // Time of last drip

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        dsr = ONE;
        chi = ONE;
    }

    // --- Math ---
    uint256 constant ONE = 10 ** 27;
    function rpow(uint x, uint n, uint base) internal pure returns (uint z) {
      assembly {
        switch x case 0 {switch n case 0 {z := base} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := base } default { z := x }
          let half := div(base, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, base)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, base)
            }
          }
        }
      }
    }
    function add(uint x, int y) internal pure returns (uint z) {
      assembly {
        z := add(x, y)
        if sgt(y, 0) { if iszero(gt(z, x)) { revert(0, 0) } }
        if slt(y, 0) { if iszero(lt(z, x)) { revert(0, 0) } }
      }
    }
    function sub(uint x, int y) internal pure returns (uint z) {
      assembly {
        z := sub(x, y)
        if slt(y, 0) { if iszero(gt(z, x)) { revert(0, 0) } }
        if sgt(y, 0) { if iszero(lt(z, x)) { revert(0, 0) } }
      }
    }
    function mul(uint x, int y) internal pure returns (int z) {
      assembly {
        z := mul(x, y)
        if slt(x, 0) { revert(0, 0) }
        if iszero(eq(y, 0)) { if iszero(eq(sdiv(z, y), x)) { revert(0, 0) } }
      }
    }
    function sub(uint x, uint y) internal pure returns (int z) {
        z = int(x) - int(y);
        require(int(x) >= 0 && int(y) >= 0);
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / ONE;
    }

    function b32(address a) internal pure returns (bytes32) {
        return bytes32(bytes20(a));
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) public note auth {
        if (what == "dsr") dsr = data;
    }
    function file(bytes32 what, bytes32 data) public note auth {
        if (what == "vow") vow = data;
    }

    // --- Savings Rate Accumulation ---
    function drip() public note {
        require(now >= rho);
        int chi_ = sub(rmul(rpow(dsr, now - rho, ONE), chi), chi);
        chi = add(chi, chi_);
        rho  = uint48(now);
        vat.heal(vow, b32(address(this)), -mul(Pie, chi_));
    }

    // --- Savings Dai Management ---
    function save(int wad) public note {
        bytes32 guy = b32(msg.sender);
        pie[guy] = add(pie[guy], wad);
        Pie      = add(Pie,      wad);
        vat.move(guy, b32(address(this)), mul(chi, wad));
    }
    function move(bytes32 src, bytes32 dst, int wad) public auth {
        pie[src] = sub(pie[src], wad);
        pie[dst] = add(pie[dst], wad);
    }
}
