/// frob.2.sol -- Dai CDP user interface

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

interface PitI {
  function wards(address guy) external returns (bool can);
  function rely(address guy) external;
  function deny(address guy) external;
  function live() external returns (bool);
  function Line() external returns (uint256);
  function vat() external returns (address);
  function ilks(bytes32 ilk) external returns (uint256 spot, uint256 line);
  function file(bytes32 what, uint256 data) external;
  function file(bytes32 ilk, bytes32 what, uint256 data) external;
  function frob(bytes32 ilk, int256 dink, int256 dart) external;
}

contract Pit {
  constructor (address vat_) public {
    assembly {
      // set vat = vat_
      codecopy(0, sub(codesize, 32), 32)
      sstore(4, mload(0))

      // set live = true
      sstore(2, 1)

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
      if eq(sig, 0xd9638d36 /*   function ilks(bytes32 ilk) external returns (uint256 spot, uint256 line); */) {
        let hash_0 := hash2(1, calldataload(4))
        mstore(64, sload(hash_0))
        mstore(96, sload(add(hash_0, 1)))
        return(64, 64)
      }
      if eq(sig, 0x957aa58c /*   function live() external returns (bool); */) {
        mstore(64, sload(2))
        return(64, 32)
      }
      if eq(sig, 0xbabe8a3f /*   function Line() external returns (uint256); */) {
        mstore(64, sload(3))
        return(64, 32)
      }
      if eq(sig, 0x36569e77 /*   function vat() external returns (address); */) {
        mstore(64, sload(4))
        return(64, 32)
      }
      if eq(sig, 0x29ae8114 /*   function file(bytes32 what, uint256 data) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        // if what == "Line" set Line = data
        if eq(calldataload(4), "Line") { sstore(3, calldataload(36)) }

        stop()
      }
      if eq(sig, 0x1a0b287e /*   function file(bytes32 ilk, bytes32 what, uint256 data) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash2(1, calldataload(4))

        // if what == "spot" set spot = data
        if eq(calldataload(36), "spot") { sstore(hash_0, calldataload(68)) }

        // if what == "line" set line = data
        if eq(calldataload(36), "line") { sstore(add(hash_0, 1), calldataload(68)) }

        stop()
      }
      if eq(sig, 0x5a984ded /*   function frob(bytes32 ilk, int256 dink, int256 dart) external; */) {

        // put bytes4(keccak256("tune(bytes32,bytes32,bytes32,bytes32,int256,int256)")) << 28 bytes
        mstore(0, 0x5dd6471a00000000000000000000000000000000000000000000000000000000)
        // put ilk
        mstore(4, calldataload(4))
        // put msg.sender
        mstore(36, caller)
        // put msg.sender
        mstore(68, caller)
        // put msg.sender
        mstore(100, caller)
        // put dink
        mstore(132, calldataload(36))
        // put dart
        mstore(164, calldataload(68))
        // iff vat.call("tune(bytes32,bytes32,bytes32,bytes32,int256,int256)", ilk, msg.sender, dink, dart) != 0
        if iszero(call(gas, sload(4), 0, 0, 196, 0, 0)) { revert(0, 0) }

        // put bytes4(keccak256("ilks(bytes32)")) << 28 bytes
        mstore(0, 0xd9638d3600000000000000000000000000000000000000000000000000000000)
        // put ilk
        mstore(4, calldataload(4))
        // iff vat.call("ilks(bytes32)", ilk) != 0
        if iszero(call(gas, sload(4), 0, 0, 36, 0, 128)) { revert(0, 0) }

        // rate, Art := vat.ilks(ilk)
        let take := mload(0)
        let rate := mload(32)
        let Ink := mload(32)
        let Art := mload(64)

        // put bytes4(keccak256("urns(bytes32,bytes32)")) << 28 bytes
        mstore(0, 0x26e2748200000000000000000000000000000000000000000000000000000000)
        // put ilk
        mstore(4, calldataload(4))
        // put msg.sender
        mstore(36, caller)
        // iff vat.call("urns(bytes32,bytes32)", ilk, msg.sender) != 0
        if iszero(call(gas, sload(4), 0, 0, 68, 0, 64)) { revert(0, 0) }

        // ink, art := vat.urns(ilk, msg.sender)
        let ink := mload(0)
        let art := mload(32)

        // put bytes4(keccak256("debt()")) << 28 bytes
        mstore(0, 0x0dca59c100000000000000000000000000000000000000000000000000000000)
        // iff vat.call("debt()") != 0
        if iszero(call(gas, sload(4), 0, 0, 4, 0, 32)) { revert(0, 0) }

        // debt := vat.debt()
        let debt := mload(0)

        let hash_0 := hash2(1, calldataload(4))

        // spot, line := ilks[ilk]
        let spot := sload(hash_0)
        let line := sload(add(hash_0, 1))

        // calm := (umul(Art, rate) <= umul(line, 10**27)) && (Tab < umul(Line, 10**27))
        let calm := and(iszero(gt(umul(Art, rate), umul(line, 1000000000000000000000000000))),
                        lt(debt, umul(sload(3), 1000000000000000000000000000)))

        // cool := dart <= 0
        let cool := iszero(sgt(calldataload(68), 0))

        // firm := dink >= 0
        let firm := iszero(slt(calldataload(36), 0))

        // safe := umul(ink, spot) >= umul(art, rate)
        let safe := iszero(lt(umul(ink, spot), umul(art, rate)))

        // iff live == 1
        if iszero(eq(sload(2), 1)) { revert(0, 0) }

        // iff rate != 0
        if eq(rate, 0) { revert(0, 0) }

        // iff (calm || cool) && (cool && firm || safe)
        if iszero(and(or(calm, cool), or(and(cool, firm), safe))) { revert(0, 0) }

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
      function umul(x, y) -> z {
        z := mul(x, y)
        // iff y == 0 || z / y == x
        if iszero(or(eq(y, 0), eq(div(z, y), x))) { revert(0, 0) }
      }
    }
  }
}
