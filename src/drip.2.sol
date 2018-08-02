/// drip.2.sol -- CDP rate updater

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
// Copyright (C) 2018 Lev Livnev <lev@liv.nev.org.uk>
// Copyright (C) 2018 Denis Erfurt <denis@dapp.org>
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

// Copyright (C) 2018 AGPL

pragma solidity ^0.4.24;

interface DripI {
  function wards(address guy) external returns (uint256 can);
  function rely(address guy) external;
  function deny(address guy) external;
  function ilks(bytes32 ilk) external returns (uint256 tax, uint48 rho);
  function vat() external returns (address);
  function vow() external returns (bytes32);
  function repo() external returns (uint256);
  function era() external returns (uint48);
  function init(bytes32 ilk) external;
  function file(bytes32 ilk, bytes32 what, uint256 data) external;
  function file(bytes32 what, uint256 data) external;
  function file(bytes32 what, bytes32 data) external;
  function drip(bytes32 ilk) external;
}

contract Drip {
  constructor (address vat_) public {
    assembly {
      let hash_0 := hash2(10, caller)

      // set wards[caller] = true
      sstore(hash_0, 1)

      codecopy(0, sub(codesize, 32), 96)

      // set vat = vat_
      sstore(2, mload(0))

      // map[key] translates to hash(key ++ idx(map))
      function hash2(b, i) -> h {
        mstore(0, i)
        mstore(32, b)
        h := keccak256(0, 64)
      }
    }
  }
  function () public {
    assembly {
      let sig := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
      if eq(sig, 0xbf353dbb /*   function wards(address guy) external returns (bool can); */) {
        let hash_0 := hash2(0, calldataload(4))
        mstore(64, sload(hash_0))
        return(64, 32)
      }
      if eq(sig, 0x65fae35e  /*   function rely(address guy) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash2(0, calldataload(4))

        // set wards[guy] = true
        sstore(hash_0, 1)

        stop()
      }
      if eq(sig, 0x9c52a7f1  /*   function deny(address guy) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash2(0, calldataload(4))

        // set wards[guy] = false
        sstore(hash_0, 0)

        stop()
      }
      if eq(sig, 0xd9638d36 /*   function ilks(bytes32 ilk) external returns (uint256 tax, uint48 rho); */) {
        let hash_0 := hash2(1, calldataload(4))
        mstore(64, sload(hash_0))
        mstore(96, sload(add(hash_0, 1)))
        return(64, 64)
      }
      if eq(sig, 0x36569e77 /*   function vat() external returns (address); */) {
        mstore(64, sload(2))
        return(64, 32)
      }
      if eq(sig, 0x626cb3c5 /*   function vow() external returns (bytes32); */) {
        mstore(64, sload(3))
        return(64, 32)
      }
      if eq(sig, 0x56ff3122 /*   function repo() external returns (uint256); */) {
        mstore(64, sload(4))
        return(64, 32)
      }
      if eq(sig, 0x143e55e0 /*   function era() external returns (uint48); */) {
        mstore(64, timestamp)
        return(64, 32)
      }
      if eq(sig, 0x3b663195 /*   function init(bytes32 ilk); */) {

        let hash_0 := hash2(1, calldataload(4))

        // iff ilks[ilk].tax == 0
        if iszero(eq(sload(hash_0), 0)) { revert(0, 0) }

        // set ilks[ilk].tax = 10**27
        sstore(hash_0, 1000000000000000000000000000)

        // set ilks[ilk].rho = era()
        sstore(add(hash_0, 1), era())

        stop()
      }
      if eq(sig, 0x1a0b287e /*   function file(bytes32 ilk, bytes32 what, uint256 data); */) {

        let hash_0 := hash2(1, calldataload(4))

        // iff i.rho == era()
        if iszero(eq(sload(add(hash_0, 1)), era())) { revert(0, 0) }

        // if what == "tax" set ilks[ilk].tax = data
        if eq(calldataload(36), "tax") { sstore(hash_0, calldataload(68)) }

        stop()
      }
      if eq(sig, 0x29ae8114 /*   function file(bytes32 what, uint256 data) external; */) {

        // if what == "repo" set repo = data
        if eq(calldataload(4), "repo") { sstore(4, calldataload(36)) }

        stop()
      }
      if eq(sig, 0xe9b674b9 /*   function file(bytes32 what, bytes32 data) external; */) {

        // if what == "vow" set vow = data
        if eq(calldataload(4), "vow") { sstore(3, calldataload(36)) }

        stop()
      }
      if eq(sig, 0x44e2a5a8 /*   function drip(bytes32 ilk) external; */) {

        let hash_0 := hash2(1, calldataload(4))

        // era_ := era()
        let era_ := era()

        let tax_i := sload(hash_0)
        let rho_i := sload(add(hash_0, 1))

        // iff era_ >= ilks[ilk].rho
        if lt(era_, rho_i) { revert(0, 0) }

        // put bytes4(keccak256("ilks(bytes32)")) << 28 bytes
        mstore(0, 0xd9638d3600000000000000000000000000000000000000000000000000000000)
        // put ilk
        mstore(4, calldataload(4))
        // iff vat.call("ilks(bytes32)", ilk) != 0
        if iszero(call(gas, sload(2), 0, 0, 36, 0, 64)) { revert(0, 0) }

        // _, rate, _, _ = vat.ilks(ilk)
        let rate := mload(32)

        let ray := 1000000000000000000000000000

        // drat := rmul(rpow(repo + tax_i, era_ - rho_i, ray), rate) - rate
        let drat := diff(rmul(rpow(uadd(sload(4), tax_i), sub(era_, rho_i), ray), rate), rate)

        // put bytes4(keccak256("fold(bytes32,bytes32,int256)")) << 28 bytes
        mstore(0, 0xe6a6a64d00000000000000000000000000000000000000000000000000000000)
        // put ilk
        mstore(4, calldataload(4))
        // put vow
        mstore(36, sload(3))
        // put drat
        mstore(68, drat)
        if iszero(call(gas, sload(2), 0, 0, 100, 0, 0)) { revert(0, 0) }

        // set ilks[ilk].rho = era_
        sstore(add(hash_0, 1), era_)

        stop()
      }

      // failed to select any of the public methods:
      revert(0, 0)

      function era() -> era_ {
        // era_ := timestamp
        // put bytes4(keccak256("era()")) << 28 bytes
        mstore(0, 0x143e55e000000000000000000000000000000000000000000000000000000000)
        // iff this.call("era()") != 0
        if iszero(call(gas, address, 0, 0, 4, 0, 32)) { revert(0, 0) }

        era_ := mload(0)
      }
      function diff(x, y) -> z {
        if slt(x, 0) { revert(0, 0) }
        if slt(y, 0) { revert(0, 0) }
        z := sub(x, y)
      }
      function pleb() -> x {
        x := iszero(eq(1, sload(hash2(0, caller))))
      }
      // map[key] translates to hash(key ++ idx(map))
      function hash2(b, i) -> h {
        mstore(0, i)
        mstore(32, b)
        h := keccak256(0, 64)
      }
      // map[key1][key2] translates to hash(key2 ++ hash(key1 ++ idx(map)))
      function hash3(b, i, j) -> h {
        mstore(0, j)
        mstore(32, i)
        mstore(64, b)
        mstore(32, keccak256(32, 64))
        h := keccak256(0, 64)
      }
      function uadd(x, y) -> z {
        z := add(x, y)
        if lt(z, x) { revert(0, 0) }
      }
      function rmul(x, y) -> z {
        z := mul(x, y)
        if iszero(eq(y, 0)) { if iszero(eq(div(z, y), x)) { revert(0, 0) } }
        z := div(z, 1000000000000000000000000000)
      }
      function rpow(x, n, base) -> z {
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
  }
}
