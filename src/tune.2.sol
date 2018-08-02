/// tune.2.sol -- Dai CDP database

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

interface VatI {
  function wards(address guy) external returns (uint256 can);
  function rely(address guy) external;
  function deny(address guy) external;
  function ilks(bytes32 ilk) external returns (uint256 take, uint256 rate, uint256 Ink, uint256 Art);
  function urns(bytes32 ilk, bytes32 lad) external returns (uint256 ink, uint256 art);
  function gem(bytes32 ilk, bytes32 lad) external returns (uint256);
  function dai(bytes32 lad) external returns (uint256);
  function sin(bytes32 lad) external returns (uint256);
  function debt() external returns (uint256);
  function vice() external returns (uint256);
  function init(bytes32 ilk) external;
  function move(bytes32 src, bytes32 dst, int256 rad) external;
  function slip(bytes32 ilk, bytes32 guy, int256 wad) external;
  function flux(bytes32 ilk, bytes32 src, bytes32 dst, int256 wad) external;
  function tune(bytes32 i, bytes32 u, bytes32 v, bytes32 w, int256 dink, int256 dart) external;
  function grab(bytes32 i, bytes32 u, bytes32 v, bytes32 w, int256 dink, int256 dart) external;
  function heal(bytes32 u, bytes32 v, int256 rad) external;
  function fold(bytes32 i, bytes32 u, int256 rate) external;
  function toll(bytes32 i, bytes32 u, int256 take) external;
}

contract Vat {
  constructor () public {
    assembly {
      let hash_0 := hash2(0, caller)

      // set wards[caller] = true
      sstore(hash_0, 1)

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
      if eq(sig, 0xd9638d36 /*   function ilks(bytes32 ilk) external returns (uint256 take, uint256 rate, uint256 Ink, uint256 Art); */) {
        let hash_0 := hash2(1, calldataload(4))
        mstore(64, sload(hash_0))
        mstore(96, sload(add(hash_0, 1)))
        mstore(128, sload(add(hash_0, 2)))
        mstore(160, sload(add(hash_0, 3)))
        return(64, 128)
      }
      if eq(sig, 0x26e27482 /*   function urns(bytes32 ilk, bytes32 lad) external returns (uint256 ink, uint256 art); */) {
        let hash_0 := hash3(2, calldataload(4), calldataload(36))
        mstore(64, sload(hash_0))
        mstore(96, sload(add(hash_0, 1)))
        return(64, 64)
      }
      if eq(sig, 0xc0912683 /*   function gem(bytes32 ilk, bytes32 lad) external returns (uint256); */) {
        let hash_0 := hash3(3, calldataload(4), calldataload(36))
        mstore(64, sload(hash_0))
        return(64, 32)
      }
      if eq(sig, 0xf53e4e69 /*   function dai(bytes32 lad) external returns (uint256); */) {
        let hash_0 := hash2(4, calldataload(4))
        mstore(64, sload(hash_0))
        return(64, 32)
      }
      if eq(sig, 0xa60f1d3e /*   function sin(bytes32 lad) external returns (uint256); */) {
        let hash_0 := hash2(5, calldataload(4))
        mstore(64, sload(hash_0))
        return(64, 32)
      }
      if eq(sig, 0x0dca59c1 /*   function debt() external returns (uint256); */) {
        mstore(64, sload(6))
        return(64, 32)
      }
      if eq(sig, 0x2d61a355 /*   function vice() external returns (uint256); */) {
        mstore(64, sload(7))
        return(64, 32)
      }
      if eq(sig, 0x3b663195 /*   function init(bytes32 ilk) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash2(1, calldataload(4))

        // iff ilks[ilk].take == 0
        if iszero(eq(sload(hash_0), 0)) { revert(0, 0) }

        // iff ilks[ilk].rate == 0
        if iszero(eq(sload(add(hash_0, 1)), 0)) { revert(0, 0) }

        // set ilks[ilk].take = 10^27
        sstore(hash_0, 1000000000000000000000000000)

        // set ilks[ilk.rate = 10^27
        sstore(add(hash_0, 1), 1000000000000000000000000000)

        stop()
      }
      if eq(sig, 0x78f19470 /*   function move(bytes32 src, bytes32 dst, int256 rad) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash2(4, calldataload(4))

        // set dai[src] -= rad
        sstore(hash_0, subui(sload(hash_0), calldataload(68)))

        let hash_1 := hash2(4, calldataload(36))

        // set dai[dst] += rad
        sstore(hash_1, addui(sload(hash_1), calldataload(68)))

        stop()
      }
      if eq(sig, 0x42066cbb /*   function slip(bytes32 ilk, bytes32 guy, int256 wad) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash3(3, calldataload(4), calldataload(36))

        // set gem[ilk][guy] += wad
        sstore(hash_0, addui(sload(hash_0), calldataload(68)))

        stop()
      }
      if eq(sig, 0xa6e41821 /*   function flux(bytes32 ilk, bytes32 src, bytes32 dst, int256 wad) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash3(3, calldataload(4), calldataload(36))

        // set gem[ilk][src] -= wad
        sstore(hash_0, subui(sload(hash_0), calldataload(100)))

        let hash_1 := hash3(3, calldataload(4), calldataload(68))

        // set gem[ilk][dst] += wad
        sstore(hash_1, addui(sload(hash_1), calldataload(100)))

        stop()
      }
      if eq(sig, 0x5dd6471a /*   function tune(bytes32 ilk, bytes32 u, bytes32 v, bytes32 w, int256 dink, int256 dart) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash3(2, calldataload(4), calldataload(36))

        // set urns[ilk][u].ink += dink
        sstore(hash_0, addui(sload(hash_0), calldataload(132)))

        // set urns[ilk][u].art += dart
        sstore(add(hash_0, 1), addui(sload(add(hash_0, 1)), calldataload(164)))

        let hash_1 := hash2(1, calldataload(4))

        // set ilks[ilk].Ink += dink
        sstore(add(hash_1, 2), addui(sload(add(hash_1, 2)), calldataload(132)))

        // set ilks[ilk].Art += dart
        sstore(add(hash_1, 3), addui(sload(add(hash_1, 3)), calldataload(164)))

        // dwar := ilks[ilk].take * dink
        let dwar := mului(sload(hash_1), calldataload(132))

        let hash_2 := hash3(3, calldataload(4), calldataload(68))

        // set gem[ilk][v] -= dwar
        sstore(hash_2, subui(sload(hash_2), dwar))

        // dtab := ilks[ilk].rate * dart
        let dtab := mului(sload(add(hash_1, 1)), calldataload(164))

        let hash_3 := hash2(4, calldataload(100))

        // set dai[w] += dtab
        sstore(hash_3, addui(sload(hash_3), dtab))

        // set debt += dtab
        sstore(6, addui(sload(6), dtab))

        stop()
      }
      if eq(sig, 0x3690ae4c /*   function grab(bytes32 ilk, bytes32 u, bytes32 v, bytes32 w, int256 dink, int256 dart) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash3(2, calldataload(4), calldataload(36))

        // set urns[ilk][u].ink += dink
        sstore(hash_0, addui(sload(hash_0), calldataload(132)))

        // set urns[ilk][u].art += dart
        sstore(add(hash_0, 1), addui(sload(add(hash_0, 1)), calldataload(164)))

        let hash_1 := hash2(1, calldataload(4))

        // set ilks[ilk].Ink += dink
        sstore(add(hash_1, 2), addui(sload(add(hash_1, 2)), calldataload(132)))

        // set ilks[ilk].Art += dart
        sstore(add(hash_1, 3), addui(sload(add(hash_1, 3)), calldataload(164)))

        // dwar := ilks[ilk].take * dink
        let dwar := mului(sload(hash_1), calldataload(132))

        let hash_2 := hash3(3, calldataload(4), calldataload(68))

        // set gem[ilk][v] -= dwar
        sstore(hash_2, subui(sload(hash_2), dwar))

        // dtab := ilks[ilk].rate * dart
        let dtab := mului(sload(add(hash_1, 1)), calldataload(164))

        let hash_3 := hash2(5, calldataload(100))

        // set sin[w] -= dtab
        sstore(hash_3, subui(sload(hash_3), dtab))

        // set vice -= dtab
        sstore(7, subui(sload(7), dtab))

        stop()
      }
      if eq(sig, 0x990a5f63 /*   function heal(bytes32 u, bytes32 v, int256 rad) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash2(5, calldataload(4))

        // set sin[u] -= rad
        sstore(hash_0, subui(sload(hash_0), calldataload(68)))

        let hash_1 := hash2(4, calldataload(36))

        // set dai[v] -= rad
        sstore(hash_1, subui(sload(hash_1), calldataload(68)))

        // set vice -= rad
        sstore(7, subui(sload(7), calldataload(68)))

        // set debt -= rad
        sstore(6, subui(sload(6), calldataload(68)))

        stop()
      }
      if eq(sig, 0xe6a6a64d /*   function fold(bytes32 i, bytes32 u, int256 rate) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash2(1, calldataload(4))

        // set ilk.rate += rate
        sstore(add(hash_0, 1), addui(sload(add(hash_0, 1)), calldataload(68)))

        // rad := ilk.Art * rate
        let rad := mului(sload(add(hash_0, 3)), calldataload(68))

        let hash_1 := hash2(4, calldataload(36))

        // set dai[u] += rad
        sstore(hash_1, addui(sload(hash_1), rad))

        // set debt += rad
        sstore(6, addui(sload(6), rad))

        stop()
      }
      if eq(sig, 0x09b7a0b5 /*   function toll(bytes32 i, bytes32 u, int256 take) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash2(1, calldataload(4))

        // set ilk.take += take
        sstore(hash_0, addui(sload(hash_0), calldataload(68)))

        // rad := ilk.Ink * take
        let rad := mului(sload(add(hash_0, 2)), calldataload(68))

        let hash_1 := hash3(3, calldataload(4), calldataload(36))

        // set gem[i][u] -= rad
        sstore(hash_1, subui(sload(hash_1), rad))

        stop()
      }

      // failed to select any of the public methods:
      revert(0, 0)

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
      // map[key1][key2] translates to hash(idx(map) ++ key1 ++ key2)
      function hash3_alt(b, i, j) -> h {
        mstore(0, b)
        mstore(32, i)
        mstore(64, j)
        h := keccak256(0, 96)
      }
      function addui(x, y) -> z {
        z := add(x, y)
        // iff y <= 0 || z > x
        if sgt(y, 0) { if iszero(gt(z, x)) { revert(0, 0) } }
        // iff y >= 0 || z < x
        if slt(y, 0) { if iszero(lt(z, x)) { revert(0, 0) } }
      }
      function subui(x, y) -> z {
        z := sub(x, y)
        // iff y >= 0 || z > x
        if slt(y, 0) { if iszero(gt(z, x)) { revert(0, 0) } }
        // iff y <= 0 || z < x
        if sgt(y, 0) { if iszero(lt(z, x)) { revert(0, 0) } }
      }
      function mului(x, y) -> z {
        z := mul(x, y)
        // iff int(x) >= 0
        if slt(x, 0) { revert(0, 0) }
        // iff y == 0 || z / y == x
        if iszero(eq(y, 0)) { if iszero(eq(sdiv(z, y), x)) { revert(0, 0) } }
      }
    }
  }
}
